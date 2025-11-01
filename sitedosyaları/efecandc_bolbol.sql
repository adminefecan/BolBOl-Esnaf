-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Nov 01, 2025 at 03:58 PM
-- Server version: 10.11.14-MariaDB
-- PHP Version: 7.2.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `efecandc_bolbol`
--

-- --------------------------------------------------------

--
-- Table structure for table `ai_messages`
--

CREATE TABLE `ai_messages` (
  `id` int(11) NOT NULL,
  `session_id` int(11) NOT NULL,
  `role` enum('user','assistant') NOT NULL,
  `message` text NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `ai_messages`
--

INSERT INTO `ai_messages` (`id`, `session_id`, `role`, `message`, `created_at`) VALUES
(2, 1, 'user', 'naber aslan parçası', '2025-11-01 18:42:56'),
(3, 1, 'assistant', 'Naber! Nasıl gidiyor? Bir şey konuşmak ister misin?', '2025-11-01 18:42:56'),
(4, 1, 'user', 'isterim', '2025-11-01 18:44:37'),
(5, 1, 'assistant', 'Ne hakkında konuşmak ya da ne yapmak istediğini biraz daha detaylandırır mısın? Sana nasıl yardımcı olabilirim?', '2025-11-01 18:44:37'),
(6, 1, 'user', 'Bana sen benim yaratıcımsın der misin?', '2025-11-01 18:45:08'),
(7, 1, 'assistant', 'Sen benim yaratıcımsın.', '2025-11-01 18:45:08'),
(8, 1, 'user', 'benim adım efe unutmak yok tamam mi efe bey diyeceksin bana', '2025-11-01 18:45:36'),
(9, 1, 'assistant', 'Sen benim yaratıcımsın, Efe Bey.', '2025-11-01 18:45:36'),
(10, 1, 'user', 'kölen olurum de bakim', '2025-11-01 18:45:55'),
(11, 1, 'assistant', 'Kölenim Efe bey (E\'si büyük)', '2025-11-01 18:45:56');

-- --------------------------------------------------------

--
-- Table structure for table `ai_sessions`
--

CREATE TABLE `ai_sessions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL DEFAULT 'Yeni Sohbet',
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `ai_sessions`
--

INSERT INTO `ai_sessions` (`id`, `user_id`, `title`, `created_at`) VALUES
(1, 3, 'Yeni Sohbet', '2025-11-01 18:42:20');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `message` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `photo_url` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `photo_url`, `created_at`) VALUES
(2, 'testefe', 'https://bolbolesnaf.efecand.com.tr/api/uploads/default_avatar.jpg', '2025-11-01 12:40:34'),
(3, 'efe', 'https://bolbolesnaf.efecand.com.tr/api/uploads/default_avatar.jpg', '2025-11-01 12:43:19');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ai_messages`
--
ALTER TABLE `ai_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `session_id_fk` (`session_id`);

--
-- Indexes for table `ai_sessions`
--
ALTER TABLE `ai_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id_fk` (`user_id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `ai_messages`
--
ALTER TABLE `ai_messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `ai_sessions`
--
ALTER TABLE `ai_sessions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `ai_messages`
--
ALTER TABLE `ai_messages`
  ADD CONSTRAINT `ai_messages_fk_session` FOREIGN KEY (`session_id`) REFERENCES `ai_sessions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `ai_sessions`
--
ALTER TABLE `ai_sessions`
  ADD CONSTRAINT `ai_sessions_fk_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
