CREATE TABLE `status_comments` (
	`id` text PRIMARY KEY NOT NULL,
	`post` text NOT NULL,
	`author` text NOT NULL,
	`text` text NOT NULL,
	`created` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `status_follows` (
	`follower` text NOT NULL,
	`target` text NOT NULL,
	PRIMARY KEY(`follower`, `target`)
);
--> statement-breakpoint
CREATE TABLE `status_likes` (
	`post` text NOT NULL,
	`person` text NOT NULL,
	PRIMARY KEY(`post`, `person`)
);
--> statement-breakpoint
CREATE TABLE `status_media` (
	`id` text PRIMARY KEY NOT NULL,
	`owner` text NOT NULL,
	`mime` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `status_people` (
	`id` text PRIMARY KEY NOT NULL,
	`profile` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `status_posts` (
	`id` text PRIMARY KEY NOT NULL,
	`author` text NOT NULL,
	`text` text NOT NULL,
	`visibility` text NOT NULL,
	`media` text,
	`music` text,
	`poll` text,
	`created` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `status_votes` (
	`post` text NOT NULL,
	`voter` text NOT NULL,
	`choice` integer NOT NULL,
	PRIMARY KEY(`post`, `voter`)
);
