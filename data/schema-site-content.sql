-- database: /workspace/data/site-cern.sqlite3

create table sites (
    id text not null,
    scheme text not null,
    hostname text not null,
    description text not null,
    created integer not null,
    last_checked integer not null,

    primary key (id)
);

create table content_types (
    id text not null,
    description text not null,

    primary key (id)
);

create table content (
    site_id text not null,
    id text not null,
    content text not null,
    modified_header_field text not null,
    modified_at integer not null,
    content_type_id text not null,
    created integer not null,
    updated integer not null,

    primary key (site_id, id),
    foreign key (site_id) references sites (id)
    foreign key (content_type_id) references content_types (id)
);

