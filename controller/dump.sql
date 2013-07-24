CREATE TABLE `users` (`id` integer PRIMARY KEY AUTO_INCREMENT, `name` varchar(255), `password` varchar(255), b_ques integer, a_ques integer);
INSERT INTO users (id, name,password,  b_ques,  a_ques) VALUES(1,'aaa','e5e9fa1ba31ecd1ae84f75caaa474f3a663f05f4',0,0);
INSERT INTO users (id, name,password,  b_ques,  a_ques) VALUES(2,'riceisland','6b47abf6e3c48c7af4229a088c59b66bc926450a',0,0);
INSERT INTO users (id, name,password,  b_ques,  a_ques) VALUES(3,'yonejima','78988010b890ce6f4d2136481f392787ec6d6106',1,0);
INSERT INTO users (id, name,password,  b_ques,  a_ques) VALUES(4,'','da39a3ee5e6b4b0d3255bfef95601890afd80709',0,0);
INSERT INTO users (id, name,password,  b_ques,  a_ques) VALUES(5,'test4','5cb138284d431abd6a053a56625ec088bfb88912',NULL,NULL);
CREATE TABLE `twitter_oauths` (`uid` varchar(255), `twitter_access_token` varchar(255), `twitter_access_token_secret` varchar(255));
INSERT INTO twitter_oauths (uid,twitter_access_token, twitter_access_token_secret) VALUES('3','135738273-7blNqQS2ZyzlyfaYgavwma2hrxZTKcMlt6OwoaYh','6ERZTZlIOutviRzDIZjte6ZuGkMtH7Pf7b02FLkbM');