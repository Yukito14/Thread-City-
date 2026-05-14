-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: thread_city
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `blocks`
--

DROP TABLE IF EXISTS `blocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blocks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `blocker_id` int NOT NULL,
  `blocked_id` int NOT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `blocks_blocker_id_blocked_id_key` (`blocker_id`,`blocked_id`),
  KEY `blocks_blocked_id_fkey` (`blocked_id`),
  CONSTRAINT `blocks_blocked_id_fkey` FOREIGN KEY (`blocked_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `blocks_blocker_id_fkey` FOREIGN KEY (`blocker_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `blocks`
--

LOCK TABLES `blocks` WRITE;
/*!40000 ALTER TABLE `blocks` DISABLE KEYS */;
INSERT INTO `blocks` VALUES (1,5,4,'2026-05-26 19:28:33.000');
/*!40000 ALTER TABLE `blocks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dm_conversations`
--

DROP TABLE IF EXISTS `dm_conversations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dm_conversations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user1_id` int NOT NULL,
  `user2_id` int NOT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `dm_conversations_user1_id_user2_id_key` (`user1_id`,`user2_id`),
  KEY `dm_conversations_user2_id_fkey` (`user2_id`),
  CONSTRAINT `dm_conversations_user1_id_fkey` FOREIGN KEY (`user1_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `dm_conversations_user2_id_fkey` FOREIGN KEY (`user2_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dm_conversations`
--

LOCK TABLES `dm_conversations` WRITE;
/*!40000 ALTER TABLE `dm_conversations` DISABLE KEYS */;
INSERT INTO `dm_conversations` VALUES (1,2,1,'2026-05-25 19:28:33.000'),(2,2,3,'2026-05-26 19:28:33.000'),(3,1,4,'2026-05-27 07:28:33.000');
/*!40000 ALTER TABLE `dm_conversations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `follows`
--

DROP TABLE IF EXISTS `follows`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `follows` (
  `id` int NOT NULL AUTO_INCREMENT,
  `follower_id` int NOT NULL,
  `following_id` int NOT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `follows_follower_id_following_id_key` (`follower_id`,`following_id`),
  KEY `follows_following_id_fkey` (`following_id`),
  CONSTRAINT `follows_follower_id_fkey` FOREIGN KEY (`follower_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `follows_following_id_fkey` FOREIGN KEY (`following_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `follows`
--

LOCK TABLES `follows` WRITE;
/*!40000 ALTER TABLE `follows` DISABLE KEYS */;
INSERT INTO `follows` VALUES (1,2,1,'2026-05-27 14:28:33.000'),(2,2,3,'2026-05-27 15:28:33.000'),(3,1,2,'2026-05-27 16:28:33.000'),(4,3,2,'2026-05-27 17:28:33.000'),(5,4,2,'2026-05-27 17:58:33.000'),(6,5,2,'2026-05-27 18:28:33.000'),(7,4,1,'2026-05-27 18:38:33.000'),(8,5,3,'2026-05-27 18:48:33.000'),(9,5,4,'2026-05-27 20:41:04.834');
/*!40000 ALTER TABLE `follows` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hashtags`
--

DROP TABLE IF EXISTS `hashtags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hashtags` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tag_name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `hashtags_tag_name_key` (`tag_name`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hashtags`
--

LOCK TABLES `hashtags` WRITE;
/*!40000 ALTER TABLE `hashtags` DISABLE KEYS */;
INSERT INTO `hashtags` VALUES (1,'daily','2026-05-27 19:28:33.000'),(2,'mood','2026-05-27 19:28:33.000'),(3,'coffee','2026-05-27 19:28:33.000'),(4,'life','2026-05-27 19:28:33.000'),(5,'chill','2026-05-27 19:28:33.000'),(6,'study','2026-05-27 19:28:33.000'),(7,'food','2026-05-27 19:28:33.000'),(8,'thoughts','2026-05-27 19:28:33.000'),(9,'weekend','2026-05-27 19:28:33.000'),(10,'rainyday','2026-05-27 19:28:33.000');
/*!40000 ALTER TABLE `hashtags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `likes`
--

DROP TABLE IF EXISTS `likes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `likes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `post_id` int NOT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `likes_user_id_post_id_key` (`user_id`,`post_id`),
  KEY `likes_post_id_fkey` (`post_id`),
  CONSTRAINT `likes_post_id_fkey` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `likes_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `likes`
--

LOCK TABLES `likes` WRITE;
/*!40000 ALTER TABLE `likes` DISABLE KEYS */;
INSERT INTO `likes` VALUES (1,1,1,'2026-05-27 14:28:33.000'),(2,3,1,'2026-05-27 15:28:33.000'),(3,4,1,'2026-05-27 16:28:33.000'),(4,5,1,'2026-05-27 17:28:33.000'),(5,2,2,'2026-05-27 15:28:33.000'),(6,3,2,'2026-05-27 16:28:33.000'),(7,4,2,'2026-05-27 17:28:33.000'),(8,2,3,'2026-05-27 16:28:33.000'),(9,1,3,'2026-05-27 17:28:33.000'),(10,5,4,'2026-05-27 17:58:33.000'),(11,2,5,'2026-05-27 18:08:33.000'),(12,1,8,'2026-05-27 19:08:33.000'),(13,3,8,'2026-05-27 19:13:33.000'),(14,4,8,'2026-05-27 19:18:33.000'),(16,5,10,'2026-05-27 20:39:57.688'),(17,4,10,'2026-05-27 21:18:01.472');
/*!40000 ALTER TABLE `likes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `messages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `conversation_id` int NOT NULL,
  `sender_id` int NOT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `messages_conversation_id_fkey` (`conversation_id`),
  KEY `messages_sender_id_fkey` (`sender_id`),
  CONSTRAINT `messages_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `dm_conversations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `messages_sender_id_fkey` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `messages`
--

LOCK TABLES `messages` WRITE;
/*!40000 ALTER TABLE `messages` DISABLE KEYS */;
INSERT INTO `messages` VALUES (1,1,2,'Hôm nay tự nhiên thấy hơi mệt, muốn biến mất một chút.',1,'2026-05-25 19:28:33.000'),(2,1,1,'Vậy nghỉ một chút đi. Không cần lúc nào cũng phải ổn đâu.',1,'2026-05-25 19:38:33.000'),(3,1,2,'Ừ, chắc tối nay tắt thông báo rồi ngủ sớm.',1,'2026-05-26 19:28:33.000'),(4,2,3,'Mai đi cà phê không? Quán cũ á.',0,'2026-05-27 13:28:33.000'),(5,2,2,'Đi chứ, lâu rồi chưa ngồi nói chuyện đàng hoàng.',0,'2026-05-27 14:28:33.000'),(6,3,4,'Dạo này thấy Threads vui ghê, toàn đọc mấy dòng vu vơ mà cuốn.',1,'2026-05-27 16:28:33.000');
/*!40000 ALTER TABLE `messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `actor_id` int NOT NULL,
  `post_id` int DEFAULT NULL,
  `type` enum('like','reply','follow','repost','mention') COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `notifications_actor_id_fkey` (`actor_id`),
  KEY `notifications_post_id_fkey` (`post_id`),
  KEY `notifications_user_id_fkey` (`user_id`),
  CONSTRAINT `notifications_actor_id_fkey` FOREIGN KEY (`actor_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_post_id_fkey` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `notifications_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (1,2,1,1,'like',0,'2026-05-27 14:28:33.000'),(2,2,3,1,'like',0,'2026-05-27 15:28:33.000'),(3,2,1,NULL,'follow',1,'2026-05-27 16:28:33.000'),(4,1,2,2,'reply',0,'2026-05-27 18:28:33.000'),(5,2,3,8,'repost',0,'2026-05-27 19:18:33.000'),(6,4,5,NULL,'follow',0,'2026-05-27 20:41:04.861'),(7,5,4,10,'like',0,'2026-05-27 21:18:01.542');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `post_counts`
--

DROP TABLE IF EXISTS `post_counts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `post_counts` (
  `post_id` int NOT NULL,
  `like_count` int NOT NULL DEFAULT '0',
  `comment_count` int NOT NULL DEFAULT '0',
  `repost_count` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`post_id`),
  CONSTRAINT `post_counts_post_id_fkey` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `post_counts`
--

LOCK TABLES `post_counts` WRITE;
/*!40000 ALTER TABLE `post_counts` DISABLE KEYS */;
INSERT INTO `post_counts` VALUES (1,4,0,1),(2,3,1,0),(3,2,0,1),(4,1,0,0),(5,1,0,0),(6,0,1,0),(7,0,0,0),(8,3,1,1),(9,0,0,0),(10,2,0,0);
/*!40000 ALTER TABLE `post_counts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `post_hashtags`
--

DROP TABLE IF EXISTS `post_hashtags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `post_hashtags` (
  `post_id` int NOT NULL,
  `hashtag_id` int NOT NULL,
  PRIMARY KEY (`post_id`,`hashtag_id`),
  KEY `post_hashtags_hashtag_id_fkey` (`hashtag_id`),
  CONSTRAINT `post_hashtags_hashtag_id_fkey` FOREIGN KEY (`hashtag_id`) REFERENCES `hashtags` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `post_hashtags_post_id_fkey` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `post_hashtags`
--

LOCK TABLES `post_hashtags` WRITE;
/*!40000 ALTER TABLE `post_hashtags` DISABLE KEYS */;
INSERT INTO `post_hashtags` VALUES (3,1),(4,1),(1,2),(2,3),(2,4),(5,5),(8,5),(5,7),(1,8),(3,8),(8,10);
/*!40000 ALTER TABLE `post_hashtags` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `post_media`
--

DROP TABLE IF EXISTS `post_media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `post_media` (
  `id` int NOT NULL AUTO_INCREMENT,
  `post_id` int NOT NULL,
  `media_url` varchar(2048) COLLATE utf8mb4_unicode_ci NOT NULL,
  `media_type` enum('image','video') COLLATE utf8mb4_unicode_ci NOT NULL,
  `order_index` int NOT NULL DEFAULT '0',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `post_media_post_id_fkey` (`post_id`),
  CONSTRAINT `post_media_post_id_fkey` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `post_media`
--

LOCK TABLES `post_media` WRITE;
/*!40000 ALTER TABLE `post_media` DISABLE KEYS */;
INSERT INTO `post_media` VALUES (1,1,'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=900','image',0,'2026-05-27 13:28:33.000'),(2,2,'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=900','image',0,'2026-05-27 14:28:33.000'),(3,3,'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=900','image',0,'2026-05-27 15:28:33.000'),(4,4,'https://images.unsplash.com/photo-1516321497487-e288fb19713f?w=900','image',0,'2026-05-27 16:28:33.000'),(5,5,'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900','image',0,'2026-05-27 17:28:33.000'),(6,8,'https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?w=900','image',0,'2026-05-27 18:58:33.000'),(7,10,'https://firebasestorage.googleapis.com/v0/b/thread-b4d7b.firebasestorage.app/o/posts%2F1779910396425_scaled_1000013207.jpg?alt=media&token=a270a484-0c4f-44d0-9f61-7d374c280539','image',0,'2026-05-27 19:33:23.132');
/*!40000 ALTER TABLE `post_media` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `posts`
--

DROP TABLE IF EXISTS `posts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `posts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `parent_id` int DEFAULT NULL,
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` enum('post','comment','reply','quote') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'post',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL,
  `deleted_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `posts_user_id_fkey` (`user_id`),
  KEY `posts_parent_id_fkey` (`parent_id`),
  CONSTRAINT `posts_parent_id_fkey` FOREIGN KEY (`parent_id`) REFERENCES `posts` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `posts_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `posts`
--

LOCK TABLES `posts` WRITE;
/*!40000 ALTER TABLE `posts` DISABLE KEYS */;
INSERT INTO `posts` VALUES (1,2,NULL,'Có những ngày không buồn hẳn, cũng không vui hẳn. Chỉ là thấy mình cần yên tĩnh một chút thôi. #mood #thoughts','post','2026-05-27 13:28:33.000','2026-05-27 13:28:33.000',NULL),(2,1,NULL,'Sáng nay uống cà phê hơi đắng, nhưng tự nhiên thấy hợp tâm trạng ghê. Có lẽ người lớn là vậy, càng lớn càng thích những thứ không quá ngọt. #coffee #life','post','2026-05-27 14:28:33.000','2026-05-27 14:28:33.000',NULL),(3,3,NULL,'Đi ngang qua một con đường quen, tự nhiên nhớ lại phiên bản mình của mấy năm trước. Hồi đó nhiều lo lắng thật, nhưng cũng dễ vui hơn bây giờ. #daily #thoughts','post','2026-05-27 15:28:33.000','2026-05-27 15:28:33.000',NULL),(4,4,NULL,'Mọi người có bao giờ mở điện thoại lên định làm gì đó, xong quên luôn mình mở để làm gì không? Tui bị hoài luôn 😭 #daily','post','2026-05-27 16:28:33.000','2026-05-27 16:28:33.000',NULL),(5,5,NULL,'Một bữa ăn ngon đôi khi cứu được cả một ngày tệ. Hôm nay chỉ cần ăn no, tắm nước ấm rồi ngủ sớm là thấy đời dễ chịu hơn nhiều. #food #chill','post','2026-05-27 17:28:33.000','2026-05-27 17:28:33.000',NULL),(6,2,2,'Đúng kiểu càng lớn càng ít thích trà sữa, nhưng lại nghiện cà phê hơn á.','comment','2026-05-27 18:28:33.000','2026-05-27 18:28:33.000',NULL),(7,1,6,'Cà phê giống mood người lớn thiệt, đắng trước rồi tỉnh sau.','reply','2026-05-27 18:38:33.000','2026-05-27 18:38:33.000',NULL),(8,2,NULL,'Trời mưa mà được nằm trong phòng nghe nhạc, không ai nhắn gì, không phải đi đâu, tự nhiên thấy bình yên ghê. #rainyday #chill','post','2026-05-27 18:58:33.000','2026-05-27 18:58:33.000',NULL),(9,5,8,'abc','comment','2026-05-27 19:30:52.065','2026-05-27 19:30:52.065',NULL),(10,5,NULL,'ngày mới tốt lành','post','2026-05-27 19:33:23.127','2026-05-27 19:33:23.127',NULL);
/*!40000 ALTER TABLE `posts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reposts`
--

DROP TABLE IF EXISTS `reposts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reposts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `post_id` int NOT NULL,
  `quote_content` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `reposts_post_id_fkey` (`post_id`),
  KEY `reposts_user_id_fkey` (`user_id`),
  CONSTRAINT `reposts_post_id_fkey` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `reposts_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reposts`
--

LOCK TABLES `reposts` WRITE;
/*!40000 ALTER TABLE `reposts` DISABLE KEYS */;
INSERT INTO `reposts` VALUES (1,1,1,'Có những ngày chỉ cần được im lặng thôi là đủ.','2026-05-27 15:28:33.000'),(2,2,3,NULL,'2026-05-27 17:28:33.000'),(3,3,8,'Mưa + nhạc + phòng tối = combo chữa lành.','2026-05-27 19:18:33.000');
/*!40000 ALTER TABLE `reposts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `firebase_uid` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nickname` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_hash` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bio` text COLLATE utf8mb4_unicode_ci,
  `avatar_url` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_verified` tinyint(1) NOT NULL DEFAULT '0',
  `status` enum('active','banned','deactivated') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_firebase_uid_key` (`firebase_uid`),
  UNIQUE KEY `users_username_key` (`username`),
  UNIQUE KEY `users_email_key` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'seed_user_uid_123','thanh_hau','hau@gmail.com','Thanh Hậu','hashed_password_here','Thích những ngày trời nhẹ, cà phê vừa đủ đắng và vài dòng nghĩ vu vơ.','https://api.dicebear.com/7.x/avataaars/png?seed=thanh_hau',0,'active','2026-05-27 17:05:35.593','2026-05-27 19:28:33.000'),(2,'ZneFfHO0TFhuczeKBaD197VOWAG2','nguyenanhthu0310','nguyenanhthu03102005@gmail.com','Nguyễn Anh Thư',NULL,'Hay nghĩ nhiều, thích chụp ảnh trời, mê những điều nhỏ xíu nhưng dễ thương 🌸','https://api.dicebear.com/7.x/avataaars/png?seed=nguyenanhthu03102005',0,'active','2026-05-27 18:11:53.082','2026-05-27 19:28:33.000'),(3,'EAAAadQKacS56mmJuh1v7Lyo75v2','linh.may','user2@gmail.com','Linh Mây',NULL,'Sáng cà phê, tối nghe nhạc. Đôi khi biến mất để nạp lại năng lượng.','https://api.dicebear.com/7.x/avataaars/png?seed=linh_may',0,'active','2026-05-27 19:00:15.824','2026-05-27 19:28:33.000'),(4,'3mwB2cOYVPTT6au7FYuSRiDRo2B3','minh.an','user3@gmail.com','Minh An',NULL,'Người hướng nội nhưng thích đọc chuyện của người khác trên Threads.','https://api.dicebear.com/7.x/avataaars/png?seed=minh_an',0,'active','2026-05-27 19:01:21.242','2026-05-27 19:28:33.000'),(5,'sCRe4FjPUrNem9JYpYXkXDULSBY2','thao.mood','user4@gmail.com','Thảo Mood',NULL,'Mood lên xuống theo thời tiết. Đang học cách sống chậm hơn một chút.','https://api.dicebear.com/7.x/avataaars/png?seed=thao_mood',0,'active','2026-05-27 19:02:06.606','2026-05-27 19:28:33.000');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-28  6:55:13
