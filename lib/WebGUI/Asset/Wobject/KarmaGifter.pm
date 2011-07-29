package WebGUI::Asset::Wobject::KarmaGifter;

$VERSION = "1.0.0";

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use Moose;
use WebGUI::International;
use WebGUI::Definition::Asset;
extends 'WebGUI::Asset::Wobject';
use WebGUI::User;

define assetName           => "Karma Gifter";
define icon                => 'karmagifter.png';
define tableName           => 'KarmaGifter';

property templateId => (
    fieldType       => "template",
    tab             => "display",
    namespace       => "KarmaGifter",
    hoverHelp       => "Karma Gifter Template",
    label           => "Karma Gifter Template",
    defaultValue    => 'nW3McOz4DztZir2oBNXBAA',
);

property topUserLimit => (
    fieldType       => 'integer',
    tab             => 'display',
    label           => 'Top Users Count',
    defaultValue    => 100,
);

property allowGiftFrom => (
    fieldType       => 'group',
    tab             => 'security',
    label           => 'Group to allow sending karma',
    defaultValue    => '2', # Registered Users
);

property allowGiftTo => (
    fieldType       => 'group',
    tab             => 'security',
    label           => 'Group to allow receiving karma',
    defaultValue    => '2', # Registered Users
);


#-------------------------------------------------------------------

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

override prepareView => sub {
    my $self = shift;
    super();
    my $template = WebGUI::Asset::Template->new($self->session, $self->templateId);
    $template->prepare;
    $self->{_viewTemplate} = $template;
};

#-------------------------------------------------------------------

=head2 view ( )

method called by the www_view method.  Returns a processed template
to be displayed within the page style.  

=cut

sub view {
    my $self = shift;

    return $self->processTemplate($self->getTemplateVars, undef, $self->{_viewTemplate});
}

sub getTemplateVars {
    my $self = shift;
    my $form = $self->session->form;
    my $var = $self->get;
    my $userList = $self->session->db->buildArrayRefOfHashRefs("SELECT `userId`, `username`, `karma` FROM `users` WHERE `karma` > 0 AND `userId` != '1' ORDER BY `karma` DESC LIMIT ?", [$self->topUserLimit]);
    for my $user (@$userList) {
        my $u = WebGUI::User->new($self->session, $user->{userId});
        $user->{profile_link} = $u->getProfileUrl($self->getUrl());
    }
    $var->{users_loop} = $userList;
    if ($self->session->user->isInGroup($self->allowGiftFrom)) {
        if ($self->session->user->karma <= 0) {
            $var->{no_karma} = 1;
        }
        else {
            my $userForm = WebGUI::HTMLForm->new($self->session, action => $self->getUrl);
            $userForm->hidden(name => 'func', value => 'confirmGift');
            $userForm->readOnly(label => 'Your Karma', value => $self->session->user->karma);
            $userForm->text(name => 'username', label => 'Donate to', defaultValue => $form->process('username'));
            $userForm->integer(name => 'karmaAmount', label => 'Karma to transfer', defaultValue => $form->process('karmaAmount'));
            $userForm->textarea(name => 'message', label => 'Message', defaultValue => $form->process('message'));
            $userForm->submit(value => 'Send Karma');
            $var->{user_form} = $userForm->print;
        }
    }
    return $var;
}

sub www_confirmGift {
    my $self = shift;
    my $output;
    my $giftUser;
    my $transKarma = int($self->session->form->process('karmaAmount') + 0);
    my $var = $self->getTemplateVars;
    my @errors;
    $var->{errors} = \@errors;
    my $user = $self->session->user;
    if (!$user->isInGroup($self->allowGiftFrom)) {
        push @errors, {error => "You aren't allowed to send karma!"};
    }
    else {
        if (my $uid = $self->session->form->process('uid')) {
            $giftUser = WebGUI::User->new($self->session, $uid);
        }
        elsif (my $username = $self->session->form->process('username')) {
            $giftUser = WebGUI::User->newByUsername($self->session, $username);
        }
        if (!$giftUser) {
            push @errors, {error => "Not a valid username!"};
        }
        elsif (!$giftUser->isInGroup($self->allowGiftTo)) {
            push @errors, {error => sprintf "You aren't allowed to gift karma to %s!", $giftUser->username};
        }
        elsif ($giftUser->userId eq $user->userId) {
            push @errors, {error => "You can't send karma to yourself!"};
        }
        if ($transKarma <= 0) {
            push @errors, {error => sprintf "Can't transfer %d karma!", $transKarma};
        }
        if ($transKarma > $self->session->user->karma) {
            push @errors, {error => "Can't transfer more karma than you have!"};
        }
    }
    if (@errors) {
        return $self->processStyle($self->processTemplate($var, $self->templateId));
    }
    $var->{karma_gifted} = $transKarma;
    $var->{user_karma_before} = $self->session->user->karma;
    $var->{user_karma_after} = $self->session->user->karma - $transKarma;
    $var->{gifted_karma_before} = $giftUser->karma;
    $var->{gifted_karma_after} = $giftUser->karma + $transKarma;
    $var->{gifted_username} = $giftUser->profileField('alias') || $giftUser->username;
    my $message = $self->session->form->process('message');
    $var->{message} = WebGUI::HTML::format($message, 'text');
    my $f = WebGUI::HTMLForm->new($self->session, action => $self->getUrl);
    $f->hidden(name => 'func', value => 'sendGift');
    $f->hidden(name => 'karmaAmount', value => $transKarma);
    $f->hidden(name => 'message', value => $message);
    $f->hidden(name => 'uid', value => $giftUser->userId);
    $f->submit(value => 'Confirm');
    $var->{confirm_gift} = $f->print;

    return $self->processStyle($self->processTemplate($var, $self->templateId));
}

sub www_sendGift {
    my $self = shift;
    my $form = $self->session->form;
    my $user = $self->session->user;
    my $giftUser = WebGUI::User->new($self->session, $form->process('uid'));
    my $karmaTrans = int($form->process('karmaAmount') + 0);
    if (!$giftUser) {
        return $self->session->privilege->insufficient;
    }
    if (!$user->isInGroup($self->allowGiftFrom)) {
        return $self->session->privilege->insufficient;
    }
    if (!$giftUser->isInGroup($self->allowGiftTo)) {
        return $self->session->privilege->insufficient;
    }
    if ($karmaTrans <= 0 || $karmaTrans > $user->karma) {
        return $self->session->privilege->insufficient;
    }
    WebGUI::Inbox->new($self->session)->addMessage({
        userId  => $giftUser->userId,
        sentBy  => $user->userId,
        status  => 'completed',
        subject => sprintf('You have received a gift of %d karma', $karmaTrans),
        message => WebGUI::HTML::format($form->process('message') || sprintf("Here is a gift of %d karma.", $karmaTrans), 'text'),
    });
    $user->karma(-$karmaTrans, 'Karma Transfer', sprintf('Gift of karma given to %s', $giftUser->username));
    $giftUser->karma($karmaTrans, 'Karma Transfer', sprintf('Gift of karma received from %s', $user->username));

    return $self->processStyle(sprintf("<p>Successfully transfered %d karma to %s</p>", $karmaTrans, $giftUser->username) . '<p><a href="' . $self->session->url->getBackToSiteURL . '">Return to page</p>');
}

1;

