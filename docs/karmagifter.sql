SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `KarmaGifter` (
  `assetId` varchar(22) character set utf8 collate utf8_bin NOT NULL,
  `revisionDate` bigint(20) unsigned NOT NULL,
  `templateId` varchar(22) character set utf8 collate utf8_bin NOT NULL,
  `topUserLimit` int(11) default NULL,
  `allowGiftFrom` varchar(22) character set utf8 collate utf8_bin NOT NULL,
  `allowGiftTo` varchar(22) character set utf8 collate utf8_bin NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
INSERT INTO `asset` VALUES ('5hCtHk3loDhTgGHR9t4xNQ','PBasset000000000000002','000001000001000117','published','WebGUI::Asset::Template',1159989349,'3','1219407871','3',NULL,0,NULL);
INSERT INTO `assetData` VALUES ('5hCtHk3loDhTgGHR9t4xNQ',1219409787,'3','yjj82kv3SzLu0jz4NBLbSA','approved','Default Karma Gifter','Default Karma Gifter','root/import/default-karma-gifter','3','7','12',NULL,0,1,0,0,0,1186,NULL,0,1,0);
INSERT INTO `template` VALUES ('<a name=\"id<tmpl_var assetId>\" id=\"id<tmpl_var assetId>\"></a>\r\n\r\n<tmpl_if session.var.adminOn>\r\n	<p><tmpl_var controls></p>\r\n</tmpl_if>\r\n\r\n<tmpl_if displayTitle>\r\n	<h2><tmpl_var title></h2>\r\n</tmpl_if>\r\n\r\n<tmpl_if description>\r\n	<tmpl_var description>\r\n</tmpl_if>\r\n\r\n<tmpl_if confirm_gift>\r\nYou are giving <tmpl_var karma_gifted> karma to <tmpl_var gifted_username>, leaving you with <tmpl_var user_karma_after> and them with <tmpl_var gifted_karma_after>. <tmpl_var confirm_gift>\r\n<tmpl_else>\r\n\r\n<tmpl_if errors>\r\n<ul class=\"errors\">\r\n<tmpl_loop errors>\r\n<li><tmpl_var error></li>\r\n</tmpl_loop>\r\n</ul>\r\n</tmpl_if>\r\n<tmpl_if no_karma>\r\n<p>You don\'t have any karma to give.</p>\r\n<tmpl_else>\r\n<tmpl_var user_form>\r\n</tmpl_if>\r\n</tmpl_if>\r\n\r\nTop Karma Users:\r\n<ul>\r\n<tmpl_loop users_loop>\r\n<li><tmpl_var karma> - <a href=\"<tmpl_var profile_link>\"><tmpl_var username></a></li>\r\n</tmpl_loop>\r\n</ul>','KarmaGifter',1,1,'5hCtHk3loDhTgGHR9t4xNQ',1219409787,'WebGUI::Asset::Template::HTMLTemplate',NULL);
SET character_set_client = @saved_cs_client;
