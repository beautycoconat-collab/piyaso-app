import {sqliteTable,text,integer,primaryKey} from 'drizzle-orm/sqlite-core';
export const people=sqliteTable('status_people',{id:text('id').primaryKey(),profile:text('profile').notNull()});
export const posts=sqliteTable('status_posts',{id:text('id').primaryKey(),author:text('author').notNull(),text:text('text').notNull(),visibility:text('visibility').notNull(),media:text('media'),music:text('music'),poll:text('poll'),created:integer('created').notNull()});
export const follows=sqliteTable('status_follows',{follower:text('follower').notNull(),target:text('target').notNull()},t=>[primaryKey({columns:[t.follower,t.target]})]);
export const votes=sqliteTable('status_votes',{post:text('post').notNull(),voter:text('voter').notNull(),choice:integer('choice').notNull()},t=>[primaryKey({columns:[t.post,t.voter]})]);
export const likes=sqliteTable('status_likes',{post:text('post').notNull(),person:text('person').notNull()},t=>[primaryKey({columns:[t.post,t.person]})]);
export const comments=sqliteTable('status_comments',{id:text('id').primaryKey(),post:text('post').notNull(),author:text('author').notNull(),text:text('text').notNull(),created:integer('created').notNull()});
export const media=sqliteTable('status_media',{id:text('id').primaryKey(),owner:text('owner').notNull(),mime:text('mime').notNull()});
