create table notes (
    id integer primary key,
    title text not null,
    body text not null default '',
    created_at text not null default (datetime('now'))
);

insert into notes (title, body) values
    ('Welcome', 'Every page here is made on the server. Write a note below: the form posts, the server saves it and sends you to its page.');
