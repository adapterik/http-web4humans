-- SITE 

create table site (
    author text not null, 
    title text not null,
    description text not null,
    
    created_at integer not null,
    last_updated_at integer not null
)

-- USERS and AUTH

create table users (
    id text not null,
    name text not null,
    created integer not null,
    last_access integer not null,

    can_view integer not null,
    can_edit integer not null,
    can_manage integer not null,

    primary key (id)
)

create table users_auth (
    user_id text not null,
    password text not null,
    created integer not null,
    last_changed integer not null,
    last_signin integer not null,

    primary key (user_id),
    foreign key (user_id) references users(id)
)

-- ATHENTICATION SESSIONS


create table auth_sessions (
    id text not null, -- session id
    user_id text not null,
    created integer not null,
    expires integer not null,

    primary key (id),
    foreign key (user_id) references users (id)
)

-- NAVIGATION


create table endpoints (
    name text not null,
    description text not null,
    arity integer not null,
    class text not null,

    primary key (name, arity)
)

-- CMS

create table content_types (
    id text not null, 
    class text not null,
    noun text null,
    description text not null,

    primary key (id)
)

create table content (
    id text not null,
    title text not null,
    content text not null,
    abstract text null,
    author text not null,
    created timestamp not null,
    last_updated timestamp not null,
    content_type text not null,

    primary key (id)
)

create table content_tags (
    content_id text not null ,
    tag text not null,
    description text not null,

    primary key (content_id, tag)
)

-- LINKS

create table sites (
    id text not null,
    url text not null,
    title text not null,
    description text not null,
    added integer not null,
    last_checked integer no null,
    last_status test not null,

    primary key (id)
)



-- external sites

create table sites (
    id text not null,
    scheme text not null,
    hostname text not null,
    description text not null,
    created integer not null,
    last_checked integer not null,

    primary key (id)
)

create table content_types (
    id text not null,
    description text not null,

    primary key (id)
)

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
)