create table tasks (
    id integer primary key,
    text text not null,
    done integer not null default 0
);

insert into tasks (text) values
    ('Open the Notes tab, write something, reload'),
    ('Switch the theme to Dark');

-- The app's one note: row 1.
create table note (
    id integer primary key check (id = 1),
    text text not null default ''
);

insert into note (id, text) values (1, '');
