psql -U postgres -d soft_metrics --command "create table project_files
(
	id serial not null
		constraint project_files_pkey
			primary key,
	project varchar not null,
	package varchar,
	file varchar not null,
	lang varchar not null
)
;

create table project_commits
(
	id serial not null
		constraint project_commits_pkey
			primary key,
	project varchar not null,
	commit varchar not null,
	author varchar not null,
	date varchar
)
;

create table file_imports
(
	id serial not null
		constraint file_imports_pkey
			primary key,
	file_id integer
		constraint file__id
			references project_files,
	import varchar not null
)
;

create table file_classes
(
	id serial not null
		constraint file_classes_pkey
			primary key,
	file_id integer
		constraint file__id
			references project_files,
	class varchar not null,
	parrent varchar,
	loc integer
)
;

create table file_fields
(
	id serial not null
		constraint file_fields_pkey
			primary key,
	file_id integer not null
		constraint file_field_project_files_id_fk
			references project_files,
	class_id integer
		constraint file_field_file_classes_id_fk
			references file_classes,
	field varchar not null
)
;

create unique index file_field_id_uindex
	on file_fields (id)
;

create table file_fnctns_mthds
(
	id serial not null
		constraint file_fnctns_mthds_pkey
			primary key,
	file_id integer not null
		constraint file_fnctns_mthds_project_files_id_fk
			references project_files,
	class_id integer
		constraint file_fnctns_mthds_file_classes_id_fk
			references file_classes,
	funcmet varchar not null,
	loc integer
)
;

create unique index file_fnctns_mthds_id_uindex
	on file_fnctns_mthds (id)
;

" 
