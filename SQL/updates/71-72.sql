# Updating SQL from 71 to 72 - Adding AI and Cyborg Settings
# Adding AI and cyborg name/display/hologram settings to character saves

ALTER TABLE `characters`
ADD COLUMN `ai_name` VARCHAR(55) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' AFTER `cyborg_brain_type`,
ADD COLUMN `ai_core_display` VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Happy' AFTER `ai_name`,
ADD COLUMN `ai_hologram` VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'default' AFTER `ai_core_display`,
ADD COLUMN `ai_hologram_color` VARCHAR(7) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '#0099FF' AFTER `ai_hologram`,
ADD COLUMN `cyborg_name` VARCHAR(55) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' AFTER `ai_hologram_color`;
