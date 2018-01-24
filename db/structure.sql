--
-- PostgreSQL database dump
--

-- Dumped from database version 10.1
-- Dumped by pg_dump version 10.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE announcements (
    id integer NOT NULL,
    text text,
    show_until date,
    active boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE announcements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: announcements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE announcements_id_seq OWNED BY announcements.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: attachable_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE attachable_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    attachment_id integer NOT NULL,
    filename character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: attachable_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE attachable_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachable_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE attachable_journals_id_seq OWNED BY attachable_journals.id;


--
-- Name: attachment_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE attachment_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    container_id integer DEFAULT 0 NOT NULL,
    container_type character varying(30) DEFAULT ''::character varying NOT NULL,
    filename character varying DEFAULT ''::character varying NOT NULL,
    disk_filename character varying DEFAULT ''::character varying NOT NULL,
    filesize integer DEFAULT 0 NOT NULL,
    content_type character varying DEFAULT ''::character varying,
    digest character varying(40) DEFAULT ''::character varying NOT NULL,
    downloads integer DEFAULT 0 NOT NULL,
    author_id integer DEFAULT 0 NOT NULL,
    description text
);


--
-- Name: attachment_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE attachment_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachment_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE attachment_journals_id_seq OWNED BY attachment_journals.id;


--
-- Name: attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE attachments (
    id integer NOT NULL,
    container_id integer DEFAULT 0 NOT NULL,
    container_type character varying(30) DEFAULT ''::character varying NOT NULL,
    filename character varying DEFAULT ''::character varying NOT NULL,
    disk_filename character varying DEFAULT ''::character varying NOT NULL,
    filesize integer DEFAULT 0 NOT NULL,
    content_type character varying DEFAULT ''::character varying,
    digest character varying(40) DEFAULT ''::character varying NOT NULL,
    downloads integer DEFAULT 0 NOT NULL,
    author_id integer DEFAULT 0 NOT NULL,
    created_on timestamp without time zone,
    description character varying,
    file character varying,
    fulltext text,
    fulltext_tsv tsvector,
    file_tsv tsvector
);


--
-- Name: attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE attachments_id_seq OWNED BY attachments.id;


--
-- Name: attribute_help_texts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE attribute_help_texts (
    id integer NOT NULL,
    help_text text NOT NULL,
    type character varying NOT NULL,
    attribute_name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: attribute_help_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE attribute_help_texts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attribute_help_texts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE attribute_help_texts_id_seq OWNED BY attribute_help_texts.id;


--
-- Name: auth_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE auth_sources (
    id integer NOT NULL,
    type character varying(30) DEFAULT ''::character varying NOT NULL,
    name character varying(60) DEFAULT ''::character varying NOT NULL,
    host character varying(60),
    port integer,
    account character varying,
    account_password character varying DEFAULT ''::character varying,
    base_dn character varying,
    attr_login character varying(30),
    attr_firstname character varying(30),
    attr_lastname character varying(30),
    attr_mail character varying(30),
    onthefly_register boolean DEFAULT false NOT NULL,
    tls boolean DEFAULT false NOT NULL,
    attr_admin character varying
);


--
-- Name: auth_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE auth_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE auth_sources_id_seq OWNED BY auth_sources.id;


--
-- Name: boards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE boards (
    id integer NOT NULL,
    project_id integer NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    description character varying,
    "position" integer DEFAULT 1,
    topics_count integer DEFAULT 0 NOT NULL,
    messages_count integer DEFAULT 0 NOT NULL,
    last_message_id integer
);


--
-- Name: boards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE boards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE boards_id_seq OWNED BY boards.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE categories (
    id integer NOT NULL,
    project_id integer DEFAULT 0 NOT NULL,
    name character varying(256) DEFAULT ''::character varying NOT NULL,
    assigned_to_id integer
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE categories_id_seq OWNED BY categories.id;


--
-- Name: changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE changes (
    id integer NOT NULL,
    changeset_id integer NOT NULL,
    action character varying(1) DEFAULT ''::character varying NOT NULL,
    path text NOT NULL,
    from_path text,
    from_revision character varying,
    revision character varying,
    branch character varying
);


--
-- Name: changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE changes_id_seq OWNED BY changes.id;


--
-- Name: changeset_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE changeset_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    repository_id integer NOT NULL,
    revision character varying NOT NULL,
    committer character varying,
    committed_on timestamp without time zone NOT NULL,
    comments text,
    commit_date date,
    scmid character varying,
    user_id integer
);


--
-- Name: changeset_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE changeset_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: changeset_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE changeset_journals_id_seq OWNED BY changeset_journals.id;


--
-- Name: changesets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE changesets (
    id integer NOT NULL,
    repository_id integer NOT NULL,
    revision character varying NOT NULL,
    committer character varying,
    committed_on timestamp without time zone NOT NULL,
    comments text,
    commit_date date,
    scmid character varying,
    user_id integer
);


--
-- Name: changesets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE changesets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: changesets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE changesets_id_seq OWNED BY changesets.id;


--
-- Name: changesets_work_packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE changesets_work_packages (
    changeset_id integer NOT NULL,
    work_package_id integer NOT NULL
);


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE comments (
    id integer NOT NULL,
    commented_type character varying(30) DEFAULT ''::character varying NOT NULL,
    commented_id integer DEFAULT 0 NOT NULL,
    author_id integer DEFAULT 0 NOT NULL,
    comments text,
    created_on timestamp without time zone NOT NULL,
    updated_on timestamp without time zone NOT NULL
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: cost_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cost_entries (
    id integer NOT NULL,
    user_id integer NOT NULL,
    project_id integer NOT NULL,
    work_package_id integer NOT NULL,
    cost_type_id integer NOT NULL,
    units double precision NOT NULL,
    spent_on date NOT NULL,
    created_on timestamp without time zone NOT NULL,
    updated_on timestamp without time zone NOT NULL,
    comments character varying NOT NULL,
    blocked boolean DEFAULT false NOT NULL,
    overridden_costs numeric(15,4),
    costs numeric(15,4),
    rate_id integer,
    tyear integer NOT NULL,
    tmonth integer NOT NULL,
    tweek integer NOT NULL
);


--
-- Name: cost_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cost_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cost_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cost_entries_id_seq OWNED BY cost_entries.id;


--
-- Name: cost_object_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cost_object_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    project_id integer NOT NULL,
    author_id integer NOT NULL,
    subject character varying NOT NULL,
    description text,
    fixed_date date NOT NULL,
    created_on timestamp without time zone
);


--
-- Name: cost_object_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cost_object_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cost_object_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cost_object_journals_id_seq OWNED BY cost_object_journals.id;


--
-- Name: cost_objects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cost_objects (
    id integer NOT NULL,
    project_id integer NOT NULL,
    author_id integer NOT NULL,
    subject character varying NOT NULL,
    description text NOT NULL,
    type character varying NOT NULL,
    fixed_date date NOT NULL,
    created_on timestamp without time zone,
    updated_on timestamp without time zone
);


--
-- Name: cost_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cost_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cost_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cost_objects_id_seq OWNED BY cost_objects.id;


--
-- Name: cost_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cost_queries (
    id integer NOT NULL,
    user_id integer NOT NULL,
    project_id integer,
    name character varying NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    created_on timestamp without time zone NOT NULL,
    updated_on timestamp without time zone NOT NULL,
    serialized character varying(2000) NOT NULL
);


--
-- Name: cost_queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cost_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cost_queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cost_queries_id_seq OWNED BY cost_queries.id;


--
-- Name: cost_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cost_types (
    id integer NOT NULL,
    name character varying NOT NULL,
    unit character varying NOT NULL,
    unit_plural character varying NOT NULL,
    "default" boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: cost_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cost_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cost_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cost_types_id_seq OWNED BY cost_types.id;


--
-- Name: custom_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE custom_fields (
    id integer NOT NULL,
    type character varying(30) DEFAULT ''::character varying NOT NULL,
    field_format character varying(30) DEFAULT ''::character varying NOT NULL,
    regexp character varying DEFAULT ''::character varying,
    min_length integer DEFAULT 0 NOT NULL,
    max_length integer DEFAULT 0 NOT NULL,
    is_required boolean DEFAULT false NOT NULL,
    is_for_all boolean DEFAULT false NOT NULL,
    is_filter boolean DEFAULT false NOT NULL,
    "position" integer DEFAULT 1,
    searchable boolean DEFAULT false,
    editable boolean DEFAULT true,
    visible boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    multi_value boolean DEFAULT false,
    default_value text,
    name character varying
);


--
-- Name: custom_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_fields_id_seq OWNED BY custom_fields.id;


--
-- Name: custom_fields_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE custom_fields_projects (
    custom_field_id integer DEFAULT 0 NOT NULL,
    project_id integer DEFAULT 0 NOT NULL
);


--
-- Name: custom_fields_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE custom_fields_types (
    custom_field_id integer DEFAULT 0 NOT NULL,
    type_id integer DEFAULT 0 NOT NULL
);


--
-- Name: custom_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE custom_options (
    id integer NOT NULL,
    custom_field_id integer,
    "position" integer,
    default_value boolean,
    value text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: custom_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_options_id_seq OWNED BY custom_options.id;


--
-- Name: custom_styles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE custom_styles (
    id integer NOT NULL,
    logo character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    favicon character varying,
    touch_icon character varying
);


--
-- Name: custom_styles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_styles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_styles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_styles_id_seq OWNED BY custom_styles.id;


--
-- Name: custom_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE custom_values (
    id integer NOT NULL,
    customized_type character varying(30) DEFAULT ''::character varying NOT NULL,
    customized_id integer DEFAULT 0 NOT NULL,
    custom_field_id integer DEFAULT 0 NOT NULL,
    value text
);


--
-- Name: custom_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE custom_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE custom_values_id_seq OWNED BY custom_values.id;


--
-- Name: customizable_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE customizable_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    custom_field_id integer NOT NULL,
    value text
);


--
-- Name: customizable_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE customizable_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customizable_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE customizable_journals_id_seq OWNED BY customizable_journals.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0,
    attempts integer DEFAULT 0,
    handler text,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    queue character varying
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: design_colors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE design_colors (
    id integer NOT NULL,
    variable character varying,
    hexcode character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: design_colors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE design_colors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: design_colors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE design_colors_id_seq OWNED BY design_colors.id;


--
-- Name: document_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE document_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    project_id integer DEFAULT 0 NOT NULL,
    category_id integer DEFAULT 0 NOT NULL,
    title character varying(60) DEFAULT ''::character varying NOT NULL,
    description text,
    created_on timestamp without time zone
);


--
-- Name: document_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE document_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: document_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE document_journals_id_seq OWNED BY document_journals.id;


--
-- Name: documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE documents (
    id integer NOT NULL,
    project_id integer DEFAULT 0 NOT NULL,
    category_id integer DEFAULT 0 NOT NULL,
    title character varying(60) DEFAULT ''::character varying NOT NULL,
    description text,
    created_on timestamp without time zone
);


--
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE documents_id_seq OWNED BY documents.id;


--
-- Name: done_statuses_for_project; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE done_statuses_for_project (
    project_id integer,
    status_id integer
);


--
-- Name: enabled_modules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE enabled_modules (
    id integer NOT NULL,
    project_id integer,
    name character varying NOT NULL
);


--
-- Name: enabled_modules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enabled_modules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enabled_modules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enabled_modules_id_seq OWNED BY enabled_modules.id;


--
-- Name: enterprise_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE enterprise_tokens (
    id integer NOT NULL,
    encoded_token text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: enterprise_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enterprise_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enterprise_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enterprise_tokens_id_seq OWNED BY enterprise_tokens.id;


--
-- Name: enumerations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE enumerations (
    id integer NOT NULL,
    name character varying(30) DEFAULT ''::character varying NOT NULL,
    "position" integer DEFAULT 1,
    is_default boolean DEFAULT false NOT NULL,
    type character varying,
    active boolean DEFAULT true NOT NULL,
    project_id integer,
    parent_id integer
);


--
-- Name: enumerations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE enumerations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enumerations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE enumerations_id_seq OWNED BY enumerations.id;


--
-- Name: export_card_configurations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE export_card_configurations (
    id integer NOT NULL,
    name character varying,
    per_page integer,
    page_size character varying,
    orientation character varying,
    rows text,
    active boolean DEFAULT true,
    description text
);


--
-- Name: export_card_configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE export_card_configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: export_card_configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE export_card_configurations_id_seq OWNED BY export_card_configurations.id;


--
-- Name: group_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE group_users (
    group_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE journals (
    id integer NOT NULL,
    journable_type character varying,
    journable_id integer,
    user_id integer DEFAULT 0 NOT NULL,
    notes text,
    created_at timestamp without time zone NOT NULL,
    version integer DEFAULT 0 NOT NULL,
    activity_type character varying
);


--
-- Name: journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE journals_id_seq OWNED BY journals.id;


--
-- Name: labor_budget_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE labor_budget_items (
    id integer NOT NULL,
    cost_object_id integer NOT NULL,
    hours double precision NOT NULL,
    user_id integer,
    comments character varying DEFAULT ''::character varying NOT NULL,
    budget numeric(15,4)
);


--
-- Name: labor_budget_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE labor_budget_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: labor_budget_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE labor_budget_items_id_seq OWNED BY labor_budget_items.id;


--
-- Name: material_budget_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE material_budget_items (
    id integer NOT NULL,
    cost_object_id integer NOT NULL,
    units double precision NOT NULL,
    cost_type_id integer,
    comments character varying DEFAULT ''::character varying NOT NULL,
    budget numeric(15,4)
);


--
-- Name: material_budget_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE material_budget_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: material_budget_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE material_budget_items_id_seq OWNED BY material_budget_items.id;


--
-- Name: meeting_content_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE meeting_content_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    meeting_id integer,
    author_id integer,
    text text,
    locked boolean
);


--
-- Name: meeting_content_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE meeting_content_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meeting_content_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE meeting_content_journals_id_seq OWNED BY meeting_content_journals.id;


--
-- Name: meeting_contents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE meeting_contents (
    id integer NOT NULL,
    type character varying,
    meeting_id integer,
    author_id integer,
    text text,
    lock_version integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    locked boolean DEFAULT false
);


--
-- Name: meeting_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE meeting_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meeting_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE meeting_contents_id_seq OWNED BY meeting_contents.id;


--
-- Name: meeting_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE meeting_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    title character varying,
    author_id integer,
    project_id integer,
    location character varying,
    start_time timestamp without time zone,
    duration double precision
);


--
-- Name: meeting_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE meeting_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meeting_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE meeting_journals_id_seq OWNED BY meeting_journals.id;


--
-- Name: meeting_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE meeting_participants (
    id integer NOT NULL,
    user_id integer,
    meeting_id integer,
    email character varying,
    name character varying,
    invited boolean,
    attended boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: meeting_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE meeting_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meeting_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE meeting_participants_id_seq OWNED BY meeting_participants.id;


--
-- Name: meetings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE meetings (
    id integer NOT NULL,
    title character varying,
    author_id integer,
    project_id integer,
    location character varying,
    start_time timestamp without time zone,
    duration double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: meetings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE meetings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meetings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE meetings_id_seq OWNED BY meetings.id;


--
-- Name: member_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE member_roles (
    id integer NOT NULL,
    member_id integer NOT NULL,
    role_id integer NOT NULL,
    inherited_from integer
);


--
-- Name: member_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE member_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE member_roles_id_seq OWNED BY member_roles.id;


--
-- Name: members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE members (
    id integer NOT NULL,
    user_id integer DEFAULT 0 NOT NULL,
    project_id integer DEFAULT 0 NOT NULL,
    created_on timestamp without time zone,
    mail_notification boolean DEFAULT false NOT NULL
);


--
-- Name: members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE members_id_seq OWNED BY members.id;


--
-- Name: menu_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE menu_items (
    id integer NOT NULL,
    name character varying,
    title character varying,
    parent_id integer,
    options text,
    navigatable_id integer,
    type character varying
);


--
-- Name: menu_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE menu_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menu_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE menu_items_id_seq OWNED BY menu_items.id;


--
-- Name: message_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE message_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    board_id integer NOT NULL,
    parent_id integer,
    subject character varying DEFAULT ''::character varying NOT NULL,
    content text,
    author_id integer,
    replies_count integer DEFAULT 0 NOT NULL,
    last_reply_id integer,
    locked boolean DEFAULT false,
    sticky integer DEFAULT 0
);


--
-- Name: message_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE message_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE message_journals_id_seq OWNED BY message_journals.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE messages (
    id integer NOT NULL,
    board_id integer NOT NULL,
    parent_id integer,
    subject character varying DEFAULT ''::character varying NOT NULL,
    content text,
    author_id integer,
    replies_count integer DEFAULT 0 NOT NULL,
    last_reply_id integer,
    created_on timestamp without time zone NOT NULL,
    updated_on timestamp without time zone NOT NULL,
    locked boolean DEFAULT false,
    sticky integer DEFAULT 0,
    sticked_on timestamp without time zone
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE messages_id_seq OWNED BY messages.id;


--
-- Name: my_projects_overviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE my_projects_overviews (
    id integer NOT NULL,
    project_id integer DEFAULT 0 NOT NULL,
    "left" text NOT NULL,
    "right" text NOT NULL,
    top text NOT NULL,
    hidden text NOT NULL,
    created_on timestamp without time zone NOT NULL
);


--
-- Name: my_projects_overviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE my_projects_overviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: my_projects_overviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE my_projects_overviews_id_seq OWNED BY my_projects_overviews.id;


--
-- Name: news; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE news (
    id integer NOT NULL,
    project_id integer,
    title character varying(60) DEFAULT ''::character varying NOT NULL,
    summary character varying DEFAULT ''::character varying,
    description text,
    author_id integer DEFAULT 0 NOT NULL,
    created_on timestamp without time zone,
    comments_count integer DEFAULT 0 NOT NULL
);


--
-- Name: news_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE news_id_seq OWNED BY news.id;


--
-- Name: news_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE news_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    project_id integer,
    title character varying(60) DEFAULT ''::character varying NOT NULL,
    summary character varying DEFAULT ''::character varying,
    description text,
    author_id integer DEFAULT 0 NOT NULL,
    comments_count integer DEFAULT 0 NOT NULL
);


--
-- Name: news_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE news_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: news_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE news_journals_id_seq OWNED BY news_journals.id;


--
-- Name: plaintext_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE plaintext_tokens (
    id integer NOT NULL,
    user_id integer DEFAULT 0 NOT NULL,
    action character varying(30) DEFAULT ''::character varying NOT NULL,
    value character varying(40) DEFAULT ''::character varying NOT NULL,
    created_on timestamp without time zone NOT NULL
);


--
-- Name: plaintext_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plaintext_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plaintext_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plaintext_tokens_id_seq OWNED BY plaintext_tokens.id;


--
-- Name: planning_element_type_colors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE planning_element_type_colors (
    id integer NOT NULL,
    name character varying NOT NULL,
    hexcode character varying NOT NULL,
    "position" integer DEFAULT 1,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: planning_element_type_colors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE planning_element_type_colors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planning_element_type_colors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE planning_element_type_colors_id_seq OWNED BY planning_element_type_colors.id;


--
-- Name: principal_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE principal_roles (
    id integer NOT NULL,
    role_id integer NOT NULL,
    principal_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: principal_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE principal_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: principal_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE principal_roles_id_seq OWNED BY principal_roles.id;


--
-- Name: project_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_associations (
    id integer NOT NULL,
    project_a_id integer,
    project_b_id integer,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: project_associations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_associations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_associations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_associations_id_seq OWNED BY project_associations.id;


--
-- Name: project_orderings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_orderings (
    id integer NOT NULL,
    project_id integer,
    "position" integer
);


--
-- Name: project_orderings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_orderings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_orderings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_orderings_id_seq OWNED BY project_orderings.id;


--
-- Name: project_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_types (
    id integer NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    "position" integer DEFAULT 1,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: project_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_types_id_seq OWNED BY project_types.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE projects (
    id integer NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    description text,
    is_public boolean DEFAULT true NOT NULL,
    parent_id integer,
    created_on timestamp without time zone,
    updated_on timestamp without time zone,
    identifier character varying,
    status integer DEFAULT 1 NOT NULL,
    lft integer,
    rgt integer,
    project_type_id integer,
    responsible_id integer,
    work_packages_responsible_id integer
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- Name: projects_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE projects_types (
    project_id integer DEFAULT 0 NOT NULL,
    type_id integer DEFAULT 0 NOT NULL
);


--
-- Name: queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE queries (
    id integer NOT NULL,
    project_id integer,
    name character varying DEFAULT ''::character varying NOT NULL,
    filters text,
    user_id integer DEFAULT 0 NOT NULL,
    is_public boolean DEFAULT false NOT NULL,
    column_names text,
    sort_criteria text,
    group_by character varying,
    display_sums boolean DEFAULT false NOT NULL,
    timeline_visible boolean DEFAULT false,
    show_hierarchies boolean DEFAULT false,
    timeline_zoom_level integer DEFAULT 0,
    timeline_labels text
);


--
-- Name: queries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: queries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE queries_id_seq OWNED BY queries.id;


--
-- Name: rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE rates (
    id integer NOT NULL,
    valid_from date NOT NULL,
    rate numeric(15,4) NOT NULL,
    type character varying NOT NULL,
    project_id integer,
    user_id integer,
    cost_type_id integer
);


--
-- Name: rates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rates_id_seq OWNED BY rates.id;


--
-- Name: relations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE relations (
    id integer NOT NULL,
    from_id integer NOT NULL,
    to_id integer NOT NULL,
    delay integer,
    description text,
    hierarchy integer DEFAULT 0,
    relates integer DEFAULT 0,
    duplicates integer DEFAULT 0,
    blocks integer DEFAULT 0,
    follows integer DEFAULT 0,
    includes integer DEFAULT 0,
    requires integer DEFAULT 0,
    count integer DEFAULT 0 NOT NULL
);


--
-- Name: relations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE relations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: relations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE relations_id_seq OWNED BY relations.id;


--
-- Name: repositories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE repositories (
    id integer NOT NULL,
    project_id integer DEFAULT 0 NOT NULL,
    url character varying DEFAULT ''::character varying NOT NULL,
    login character varying(60) DEFAULT ''::character varying,
    password character varying DEFAULT ''::character varying,
    root_url character varying DEFAULT ''::character varying,
    type character varying,
    path_encoding character varying(64),
    log_encoding character varying(64),
    scm_type character varying NOT NULL,
    required_storage_bytes bigint DEFAULT 0 NOT NULL,
    storage_updated_at timestamp without time zone
);


--
-- Name: repositories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE repositories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repositories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE repositories_id_seq OWNED BY repositories.id;


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE role_permissions (
    id integer NOT NULL,
    permission character varying,
    role_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: role_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE role_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE role_permissions_id_seq OWNED BY role_permissions.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE roles (
    id integer NOT NULL,
    name character varying(30) DEFAULT ''::character varying NOT NULL,
    "position" integer DEFAULT 1,
    assignable boolean DEFAULT true,
    builtin integer DEFAULT 0 NOT NULL,
    type character varying(30) DEFAULT 'Role'::character varying
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE sessions (
    id integer NOT NULL,
    session_id character varying NOT NULL,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE settings (
    id integer NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    value text,
    updated_on timestamp without time zone
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE settings_id_seq OWNED BY settings.id;


--
-- Name: statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE statuses (
    id integer NOT NULL,
    name character varying(30) DEFAULT ''::character varying NOT NULL,
    is_closed boolean DEFAULT false NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    "position" integer DEFAULT 1,
    default_done_ratio integer
);


--
-- Name: statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE statuses_id_seq OWNED BY statuses.id;


--
-- Name: time_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE time_entries (
    id integer NOT NULL,
    project_id integer NOT NULL,
    user_id integer NOT NULL,
    work_package_id integer,
    hours double precision NOT NULL,
    comments character varying,
    activity_id integer NOT NULL,
    spent_on date NOT NULL,
    tyear integer NOT NULL,
    tmonth integer NOT NULL,
    tweek integer NOT NULL,
    created_on timestamp without time zone NOT NULL,
    updated_on timestamp without time zone NOT NULL,
    overridden_costs numeric(15,4),
    costs numeric(15,4),
    rate_id integer
);


--
-- Name: time_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE time_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: time_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE time_entries_id_seq OWNED BY time_entries.id;


--
-- Name: time_entry_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE time_entry_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    project_id integer NOT NULL,
    user_id integer NOT NULL,
    work_package_id integer,
    hours double precision NOT NULL,
    comments character varying,
    activity_id integer NOT NULL,
    spent_on date NOT NULL,
    tyear integer NOT NULL,
    tmonth integer NOT NULL,
    tweek integer NOT NULL,
    overridden_costs numeric(15,2),
    costs numeric(15,2),
    rate_id integer
);


--
-- Name: time_entry_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE time_entry_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: time_entry_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE time_entry_journals_id_seq OWNED BY time_entry_journals.id;


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tokens (
    id integer NOT NULL,
    user_id integer,
    type character varying,
    value character varying(128) DEFAULT ''::character varying NOT NULL,
    created_on timestamp without time zone NOT NULL,
    expires_on timestamp without time zone
);


--
-- Name: tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tokens_id_seq OWNED BY tokens.id;


--
-- Name: types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE types (
    id integer NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    "position" integer DEFAULT 1,
    is_in_roadmap boolean DEFAULT true NOT NULL,
    in_aggregation boolean DEFAULT true NOT NULL,
    is_milestone boolean DEFAULT false NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    color_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    is_standard boolean DEFAULT false NOT NULL,
    attribute_groups text
);


--
-- Name: types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE types_id_seq OWNED BY types.id;


--
-- Name: user_passwords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_passwords (
    id integer NOT NULL,
    user_id integer NOT NULL,
    hashed_password character varying(128) NOT NULL,
    salt character varying(64),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    type character varying NOT NULL
);


--
-- Name: user_passwords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_passwords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_passwords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_passwords_id_seq OWNED BY user_passwords.id;


--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_preferences (
    id integer NOT NULL,
    user_id integer DEFAULT 0 NOT NULL,
    others text,
    hide_mail boolean DEFAULT true,
    time_zone character varying,
    impaired boolean DEFAULT false
);


--
-- Name: user_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_preferences_id_seq OWNED BY user_preferences.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    login character varying(256) DEFAULT ''::character varying NOT NULL,
    firstname character varying(30) DEFAULT ''::character varying NOT NULL,
    lastname character varying(30) DEFAULT ''::character varying NOT NULL,
    mail character varying(60) DEFAULT ''::character varying NOT NULL,
    admin boolean DEFAULT false NOT NULL,
    status integer DEFAULT 1 NOT NULL,
    last_login_on timestamp without time zone,
    language character varying(5) DEFAULT ''::character varying,
    auth_source_id integer,
    created_on timestamp without time zone,
    updated_on timestamp without time zone,
    type character varying,
    identity_url character varying,
    mail_notification character varying DEFAULT ''::character varying NOT NULL,
    first_login boolean DEFAULT true NOT NULL,
    force_password_change boolean DEFAULT false,
    failed_login_count integer DEFAULT 0,
    last_failed_login_on timestamp without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: version_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE version_settings (
    id integer NOT NULL,
    project_id integer,
    version_id integer,
    display integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: version_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE version_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: version_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE version_settings_id_seq OWNED BY version_settings.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE versions (
    id integer NOT NULL,
    project_id integer DEFAULT 0 NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    description character varying DEFAULT ''::character varying,
    effective_date date,
    created_on timestamp without time zone,
    updated_on timestamp without time zone,
    wiki_page_title character varying,
    status character varying DEFAULT 'open'::character varying,
    sharing character varying DEFAULT 'none'::character varying NOT NULL,
    start_date date
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: watchers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE watchers (
    id integer NOT NULL,
    watchable_type character varying DEFAULT ''::character varying NOT NULL,
    watchable_id integer DEFAULT 0 NOT NULL,
    user_id integer
);


--
-- Name: watchers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE watchers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: watchers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE watchers_id_seq OWNED BY watchers.id;


--
-- Name: wiki_content_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE wiki_content_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    page_id integer NOT NULL,
    author_id integer,
    text text
);


--
-- Name: wiki_content_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wiki_content_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wiki_content_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE wiki_content_journals_id_seq OWNED BY wiki_content_journals.id;


--
-- Name: wiki_content_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE wiki_content_versions (
    id integer NOT NULL,
    wiki_content_id integer NOT NULL,
    page_id integer NOT NULL,
    author_id integer,
    data bytea,
    compression character varying(6) DEFAULT ''::character varying,
    comments character varying DEFAULT ''::character varying,
    updated_on timestamp without time zone NOT NULL,
    version integer NOT NULL
);


--
-- Name: wiki_content_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wiki_content_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wiki_content_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE wiki_content_versions_id_seq OWNED BY wiki_content_versions.id;


--
-- Name: wiki_contents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE wiki_contents (
    id integer NOT NULL,
    page_id integer NOT NULL,
    author_id integer,
    text text,
    updated_on timestamp without time zone NOT NULL,
    lock_version integer NOT NULL
);


--
-- Name: wiki_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wiki_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wiki_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE wiki_contents_id_seq OWNED BY wiki_contents.id;


--
-- Name: wiki_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE wiki_pages (
    id integer NOT NULL,
    wiki_id integer NOT NULL,
    title character varying NOT NULL,
    created_on timestamp without time zone NOT NULL,
    protected boolean DEFAULT false NOT NULL,
    parent_id integer,
    slug character varying NOT NULL
);


--
-- Name: wiki_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wiki_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wiki_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE wiki_pages_id_seq OWNED BY wiki_pages.id;


--
-- Name: wiki_redirects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE wiki_redirects (
    id integer NOT NULL,
    wiki_id integer NOT NULL,
    title character varying,
    redirects_to character varying,
    created_on timestamp without time zone NOT NULL
);


--
-- Name: wiki_redirects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wiki_redirects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wiki_redirects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE wiki_redirects_id_seq OWNED BY wiki_redirects.id;


--
-- Name: wikis; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE wikis (
    id integer NOT NULL,
    project_id integer NOT NULL,
    start_page character varying NOT NULL,
    status integer DEFAULT 1 NOT NULL
);


--
-- Name: wikis_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wikis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wikis_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE wikis_id_seq OWNED BY wikis.id;


--
-- Name: work_package_journals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE work_package_journals (
    id integer NOT NULL,
    journal_id integer NOT NULL,
    type_id integer DEFAULT 0 NOT NULL,
    project_id integer DEFAULT 0 NOT NULL,
    subject character varying DEFAULT ''::character varying NOT NULL,
    description text,
    due_date date,
    category_id integer,
    status_id integer DEFAULT 0 NOT NULL,
    assigned_to_id integer,
    priority_id integer DEFAULT 0 NOT NULL,
    fixed_version_id integer,
    author_id integer DEFAULT 0 NOT NULL,
    done_ratio integer DEFAULT 0 NOT NULL,
    estimated_hours double precision,
    start_date date,
    parent_id integer,
    responsible_id integer,
    cost_object_id integer,
    story_points integer,
    remaining_hours double precision
);


--
-- Name: work_package_journals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE work_package_journals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_package_journals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE work_package_journals_id_seq OWNED BY work_package_journals.id;


--
-- Name: work_packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE work_packages (
    id integer NOT NULL,
    type_id integer DEFAULT 0 NOT NULL,
    project_id integer DEFAULT 0 NOT NULL,
    subject character varying DEFAULT ''::character varying NOT NULL,
    description text,
    due_date date,
    category_id integer,
    status_id integer DEFAULT 0 NOT NULL,
    assigned_to_id integer,
    priority_id integer DEFAULT 0,
    fixed_version_id integer,
    author_id integer DEFAULT 0 NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    done_ratio integer DEFAULT 0 NOT NULL,
    estimated_hours double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    start_date date,
    responsible_id integer,
    "position" integer,
    story_points integer,
    remaining_hours double precision,
    cost_object_id integer
);


--
-- Name: work_packages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE work_packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE work_packages_id_seq OWNED BY work_packages.id;


--
-- Name: workflows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE workflows (
    id integer NOT NULL,
    type_id integer DEFAULT 0 NOT NULL,
    old_status_id integer DEFAULT 0 NOT NULL,
    new_status_id integer DEFAULT 0 NOT NULL,
    role_id integer DEFAULT 0 NOT NULL,
    assignee boolean DEFAULT false NOT NULL,
    author boolean DEFAULT false NOT NULL
);


--
-- Name: workflows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE workflows_id_seq OWNED BY workflows.id;


--
-- Name: announcements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY announcements ALTER COLUMN id SET DEFAULT nextval('announcements_id_seq'::regclass);


--
-- Name: attachable_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachable_journals ALTER COLUMN id SET DEFAULT nextval('attachable_journals_id_seq'::regclass);


--
-- Name: attachment_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachment_journals ALTER COLUMN id SET DEFAULT nextval('attachment_journals_id_seq'::regclass);


--
-- Name: attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachments ALTER COLUMN id SET DEFAULT nextval('attachments_id_seq'::regclass);


--
-- Name: attribute_help_texts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY attribute_help_texts ALTER COLUMN id SET DEFAULT nextval('attribute_help_texts_id_seq'::regclass);


--
-- Name: auth_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY auth_sources ALTER COLUMN id SET DEFAULT nextval('auth_sources_id_seq'::regclass);


--
-- Name: boards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY boards ALTER COLUMN id SET DEFAULT nextval('boards_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY categories ALTER COLUMN id SET DEFAULT nextval('categories_id_seq'::regclass);


--
-- Name: changes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY changes ALTER COLUMN id SET DEFAULT nextval('changes_id_seq'::regclass);


--
-- Name: changeset_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY changeset_journals ALTER COLUMN id SET DEFAULT nextval('changeset_journals_id_seq'::regclass);


--
-- Name: changesets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY changesets ALTER COLUMN id SET DEFAULT nextval('changesets_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: cost_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cost_entries ALTER COLUMN id SET DEFAULT nextval('cost_entries_id_seq'::regclass);


--
-- Name: cost_object_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cost_object_journals ALTER COLUMN id SET DEFAULT nextval('cost_object_journals_id_seq'::regclass);


--
-- Name: cost_objects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cost_objects ALTER COLUMN id SET DEFAULT nextval('cost_objects_id_seq'::regclass);


--
-- Name: cost_queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cost_queries ALTER COLUMN id SET DEFAULT nextval('cost_queries_id_seq'::regclass);


--
-- Name: cost_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cost_types ALTER COLUMN id SET DEFAULT nextval('cost_types_id_seq'::regclass);


--
-- Name: custom_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_fields ALTER COLUMN id SET DEFAULT nextval('custom_fields_id_seq'::regclass);


--
-- Name: custom_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_options ALTER COLUMN id SET DEFAULT nextval('custom_options_id_seq'::regclass);


--
-- Name: custom_styles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_styles ALTER COLUMN id SET DEFAULT nextval('custom_styles_id_seq'::regclass);


--
-- Name: custom_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_values ALTER COLUMN id SET DEFAULT nextval('custom_values_id_seq'::regclass);


--
-- Name: customizable_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY customizable_journals ALTER COLUMN id SET DEFAULT nextval('customizable_journals_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: design_colors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY design_colors ALTER COLUMN id SET DEFAULT nextval('design_colors_id_seq'::regclass);


--
-- Name: document_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY document_journals ALTER COLUMN id SET DEFAULT nextval('document_journals_id_seq'::regclass);


--
-- Name: documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY documents ALTER COLUMN id SET DEFAULT nextval('documents_id_seq'::regclass);


--
-- Name: enabled_modules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY enabled_modules ALTER COLUMN id SET DEFAULT nextval('enabled_modules_id_seq'::regclass);


--
-- Name: enterprise_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY enterprise_tokens ALTER COLUMN id SET DEFAULT nextval('enterprise_tokens_id_seq'::regclass);


--
-- Name: enumerations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY enumerations ALTER COLUMN id SET DEFAULT nextval('enumerations_id_seq'::regclass);


--
-- Name: export_card_configurations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY export_card_configurations ALTER COLUMN id SET DEFAULT nextval('export_card_configurations_id_seq'::regclass);


--
-- Name: journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY journals ALTER COLUMN id SET DEFAULT nextval('journals_id_seq'::regclass);


--
-- Name: labor_budget_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY labor_budget_items ALTER COLUMN id SET DEFAULT nextval('labor_budget_items_id_seq'::regclass);


--
-- Name: material_budget_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY material_budget_items ALTER COLUMN id SET DEFAULT nextval('material_budget_items_id_seq'::regclass);


--
-- Name: meeting_content_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY meeting_content_journals ALTER COLUMN id SET DEFAULT nextval('meeting_content_journals_id_seq'::regclass);


--
-- Name: meeting_contents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY meeting_contents ALTER COLUMN id SET DEFAULT nextval('meeting_contents_id_seq'::regclass);


--
-- Name: meeting_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY meeting_journals ALTER COLUMN id SET DEFAULT nextval('meeting_journals_id_seq'::regclass);


--
-- Name: meeting_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY meeting_participants ALTER COLUMN id SET DEFAULT nextval('meeting_participants_id_seq'::regclass);


--
-- Name: meetings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY meetings ALTER COLUMN id SET DEFAULT nextval('meetings_id_seq'::regclass);


--
-- Name: member_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY member_roles ALTER COLUMN id SET DEFAULT nextval('member_roles_id_seq'::regclass);


--
-- Name: members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY members ALTER COLUMN id SET DEFAULT nextval('members_id_seq'::regclass);


--
-- Name: menu_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY menu_items ALTER COLUMN id SET DEFAULT nextval('menu_items_id_seq'::regclass);


--
-- Name: message_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY message_journals ALTER COLUMN id SET DEFAULT nextval('message_journals_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages ALTER COLUMN id SET DEFAULT nextval('messages_id_seq'::regclass);


--
-- Name: my_projects_overviews id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY my_projects_overviews ALTER COLUMN id SET DEFAULT nextval('my_projects_overviews_id_seq'::regclass);


--
-- Name: news id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY news ALTER COLUMN id SET DEFAULT nextval('news_id_seq'::regclass);


--
-- Name: news_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY news_journals ALTER COLUMN id SET DEFAULT nextval('news_journals_id_seq'::regclass);


--
-- Name: plaintext_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY plaintext_tokens ALTER COLUMN id SET DEFAULT nextval('plaintext_tokens_id_seq'::regclass);


--
-- Name: planning_element_type_colors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY planning_element_type_colors ALTER COLUMN id SET DEFAULT nextval('planning_element_type_colors_id_seq'::regclass);


--
-- Name: principal_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY principal_roles ALTER COLUMN id SET DEFAULT nextval('principal_roles_id_seq'::regclass);


--
-- Name: project_associations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_associations ALTER COLUMN id SET DEFAULT nextval('project_associations_id_seq'::regclass);


--
-- Name: project_orderings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_orderings ALTER COLUMN id SET DEFAULT nextval('project_orderings_id_seq'::regclass);


--
-- Name: project_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_types ALTER COLUMN id SET DEFAULT nextval('project_types_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);


--
-- Name: queries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY queries ALTER COLUMN id SET DEFAULT nextval('queries_id_seq'::regclass);


--
-- Name: rates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY rates ALTER COLUMN id SET DEFAULT nextval('rates_id_seq'::regclass);


--
-- Name: relations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY relations ALTER COLUMN id SET DEFAULT nextval('relations_id_seq'::regclass);


--
-- Name: repositories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY repositories ALTER COLUMN id SET DEFAULT nextval('repositories_id_seq'::regclass);


--
-- Name: role_permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY role_permissions ALTER COLUMN id SET DEFAULT nextval('role_permissions_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings ALTER COLUMN id SET DEFAULT nextval('settings_id_seq'::regclass);


--
-- Name: statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY statuses ALTER COLUMN id SET DEFAULT nextval('statuses_id_seq'::regclass);


--
-- Name: time_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY time_entries ALTER COLUMN id SET DEFAULT nextval('time_entries_id_seq'::regclass);


--
-- Name: time_entry_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY time_entry_journals ALTER COLUMN id SET DEFAULT nextval('time_entry_journals_id_seq'::regclass);


--
-- Name: tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tokens ALTER COLUMN id SET DEFAULT nextval('tokens_id_seq'::regclass);


--
-- Name: types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY types ALTER COLUMN id SET DEFAULT nextval('types_id_seq'::regclass);


--
-- Name: user_passwords id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_passwords ALTER COLUMN id SET DEFAULT nextval('user_passwords_id_seq'::regclass);


--
-- Name: user_preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_preferences ALTER COLUMN id SET DEFAULT nextval('user_preferences_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: version_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY version_settings ALTER COLUMN id SET DEFAULT nextval('version_settings_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: watchers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY watchers ALTER COLUMN id SET DEFAULT nextval('watchers_id_seq'::regclass);


--
-- Name: wiki_content_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_content_journals ALTER COLUMN id SET DEFAULT nextval('wiki_content_journals_id_seq'::regclass);


--
-- Name: wiki_content_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_content_versions ALTER COLUMN id SET DEFAULT nextval('wiki_content_versions_id_seq'::regclass);


--
-- Name: wiki_contents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_contents ALTER COLUMN id SET DEFAULT nextval('wiki_contents_id_seq'::regclass);


--
-- Name: wiki_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_pages ALTER COLUMN id SET DEFAULT nextval('wiki_pages_id_seq'::regclass);


--
-- Name: wiki_redirects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_redirects ALTER COLUMN id SET DEFAULT nextval('wiki_redirects_id_seq'::regclass);


--
-- Name: wikis id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY wikis ALTER COLUMN id SET DEFAULT nextval('wikis_id_seq'::regclass);


--
-- Name: work_package_journals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY work_package_journals ALTER COLUMN id SET DEFAULT nextval('work_package_journals_id_seq'::regclass);


--
-- Name: work_packages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY work_packages ALTER COLUMN id SET DEFAULT nextval('work_packages_id_seq'::regclass);


--
-- Name: workflows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflows ALTER COLUMN id SET DEFAULT nextval('workflows_id_seq'::regclass);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: attachable_journals attachable_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachable_journals
    ADD CONSTRAINT attachable_journals_pkey PRIMARY KEY (id);


--
-- Name: attachment_journals attachment_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachment_journals
    ADD CONSTRAINT attachment_journals_pkey PRIMARY KEY (id);


--
-- Name: attachments attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id);


--
-- Name: attribute_help_texts attribute_help_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY attribute_help_texts
    ADD CONSTRAINT attribute_help_texts_pkey PRIMARY KEY (id);


--
-- Name: auth_sources auth_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY auth_sources
    ADD CONSTRAINT auth_sources_pkey PRIMARY KEY (id);


--
-- Name: boards boards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY boards
    ADD CONSTRAINT boards_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: changes changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY changes
    ADD CONSTRAINT changes_pkey PRIMARY KEY (id);


--
-- Name: changeset_journals changeset_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY changeset_journals
    ADD CONSTRAINT changeset_journals_pkey PRIMARY KEY (id);


--
-- Name: changesets changesets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY changesets
    ADD CONSTRAINT changesets_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: cost_entries cost_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cost_entries
    ADD CONSTRAINT cost_entries_pkey PRIMARY KEY (id);


--
-- Name: cost_object_journals cost_object_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cost_object_journals
    ADD CONSTRAINT cost_object_journals_pkey PRIMARY KEY (id);


--
-- Name: cost_objects cost_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cost_objects
    ADD CONSTRAINT cost_objects_pkey PRIMARY KEY (id);


--
-- Name: cost_queries cost_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cost_queries
    ADD CONSTRAINT cost_queries_pkey PRIMARY KEY (id);


--
-- Name: cost_types cost_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cost_types
    ADD CONSTRAINT cost_types_pkey PRIMARY KEY (id);


--
-- Name: custom_fields custom_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_fields
    ADD CONSTRAINT custom_fields_pkey PRIMARY KEY (id);


--
-- Name: custom_options custom_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_options
    ADD CONSTRAINT custom_options_pkey PRIMARY KEY (id);


--
-- Name: custom_styles custom_styles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_styles
    ADD CONSTRAINT custom_styles_pkey PRIMARY KEY (id);


--
-- Name: custom_values custom_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY custom_values
    ADD CONSTRAINT custom_values_pkey PRIMARY KEY (id);


--
-- Name: customizable_journals customizable_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY customizable_journals
    ADD CONSTRAINT customizable_journals_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: design_colors design_colors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY design_colors
    ADD CONSTRAINT design_colors_pkey PRIMARY KEY (id);


--
-- Name: document_journals document_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY document_journals
    ADD CONSTRAINT document_journals_pkey PRIMARY KEY (id);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: enabled_modules enabled_modules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enabled_modules
    ADD CONSTRAINT enabled_modules_pkey PRIMARY KEY (id);


--
-- Name: enterprise_tokens enterprise_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enterprise_tokens
    ADD CONSTRAINT enterprise_tokens_pkey PRIMARY KEY (id);


--
-- Name: enumerations enumerations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY enumerations
    ADD CONSTRAINT enumerations_pkey PRIMARY KEY (id);


--
-- Name: export_card_configurations export_card_configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY export_card_configurations
    ADD CONSTRAINT export_card_configurations_pkey PRIMARY KEY (id);


--
-- Name: journals journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY journals
    ADD CONSTRAINT journals_pkey PRIMARY KEY (id);


--
-- Name: labor_budget_items labor_budget_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY labor_budget_items
    ADD CONSTRAINT labor_budget_items_pkey PRIMARY KEY (id);


--
-- Name: material_budget_items material_budget_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY material_budget_items
    ADD CONSTRAINT material_budget_items_pkey PRIMARY KEY (id);


--
-- Name: meeting_content_journals meeting_content_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meeting_content_journals
    ADD CONSTRAINT meeting_content_journals_pkey PRIMARY KEY (id);


--
-- Name: meeting_contents meeting_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meeting_contents
    ADD CONSTRAINT meeting_contents_pkey PRIMARY KEY (id);


--
-- Name: meeting_journals meeting_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meeting_journals
    ADD CONSTRAINT meeting_journals_pkey PRIMARY KEY (id);


--
-- Name: meeting_participants meeting_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meeting_participants
    ADD CONSTRAINT meeting_participants_pkey PRIMARY KEY (id);


--
-- Name: meetings meetings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY meetings
    ADD CONSTRAINT meetings_pkey PRIMARY KEY (id);


--
-- Name: member_roles member_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY member_roles
    ADD CONSTRAINT member_roles_pkey PRIMARY KEY (id);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);


--
-- Name: menu_items menu_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- Name: message_journals message_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY message_journals
    ADD CONSTRAINT message_journals_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: my_projects_overviews my_projects_overviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY my_projects_overviews
    ADD CONSTRAINT my_projects_overviews_pkey PRIMARY KEY (id);


--
-- Name: news_journals news_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY news_journals
    ADD CONSTRAINT news_journals_pkey PRIMARY KEY (id);


--
-- Name: news news_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY news
    ADD CONSTRAINT news_pkey PRIMARY KEY (id);


--
-- Name: plaintext_tokens plaintext_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plaintext_tokens
    ADD CONSTRAINT plaintext_tokens_pkey PRIMARY KEY (id);


--
-- Name: planning_element_type_colors planning_element_type_colors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY planning_element_type_colors
    ADD CONSTRAINT planning_element_type_colors_pkey PRIMARY KEY (id);


--
-- Name: principal_roles principal_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY principal_roles
    ADD CONSTRAINT principal_roles_pkey PRIMARY KEY (id);


--
-- Name: project_associations project_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_associations
    ADD CONSTRAINT project_associations_pkey PRIMARY KEY (id);


--
-- Name: project_orderings project_orderings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_orderings
    ADD CONSTRAINT project_orderings_pkey PRIMARY KEY (id);


--
-- Name: project_types project_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_types
    ADD CONSTRAINT project_types_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: queries queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY queries
    ADD CONSTRAINT queries_pkey PRIMARY KEY (id);


--
-- Name: rates rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rates
    ADD CONSTRAINT rates_pkey PRIMARY KEY (id);


--
-- Name: relations relations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY relations
    ADD CONSTRAINT relations_pkey PRIMARY KEY (id);


--
-- Name: repositories repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY repositories
    ADD CONSTRAINT repositories_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: statuses statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY statuses
    ADD CONSTRAINT statuses_pkey PRIMARY KEY (id);


--
-- Name: time_entries time_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY time_entries
    ADD CONSTRAINT time_entries_pkey PRIMARY KEY (id);


--
-- Name: time_entry_journals time_entry_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY time_entry_journals
    ADD CONSTRAINT time_entry_journals_pkey PRIMARY KEY (id);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);


--
-- Name: types types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY types
    ADD CONSTRAINT types_pkey PRIMARY KEY (id);


--
-- Name: user_passwords user_passwords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_passwords
    ADD CONSTRAINT user_passwords_pkey PRIMARY KEY (id);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: version_settings version_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY version_settings
    ADD CONSTRAINT version_settings_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: watchers watchers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY watchers
    ADD CONSTRAINT watchers_pkey PRIMARY KEY (id);


--
-- Name: wiki_content_journals wiki_content_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_content_journals
    ADD CONSTRAINT wiki_content_journals_pkey PRIMARY KEY (id);


--
-- Name: wiki_content_versions wiki_content_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_content_versions
    ADD CONSTRAINT wiki_content_versions_pkey PRIMARY KEY (id);


--
-- Name: wiki_contents wiki_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_contents
    ADD CONSTRAINT wiki_contents_pkey PRIMARY KEY (id);


--
-- Name: wiki_pages wiki_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_pages
    ADD CONSTRAINT wiki_pages_pkey PRIMARY KEY (id);


--
-- Name: wiki_redirects wiki_redirects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wiki_redirects
    ADD CONSTRAINT wiki_redirects_pkey PRIMARY KEY (id);


--
-- Name: wikis wikis_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY wikis
    ADD CONSTRAINT wikis_pkey PRIMARY KEY (id);


--
-- Name: work_package_journals work_package_journals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY work_package_journals
    ADD CONSTRAINT work_package_journals_pkey PRIMARY KEY (id);


--
-- Name: work_packages work_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY work_packages
    ADD CONSTRAINT work_packages_pkey PRIMARY KEY (id);


--
-- Name: workflows workflows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT workflows_pkey PRIMARY KEY (id);


--
-- Name: boards_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX boards_project_id ON boards USING btree (project_id);


--
-- Name: changesets_changeset_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changesets_changeset_id ON changes USING btree (changeset_id);


--
-- Name: changesets_repos_rev; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX changesets_repos_rev ON changesets USING btree (repository_id, revision);


--
-- Name: changesets_repos_scmid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX changesets_repos_scmid ON changesets USING btree (repository_id, scmid);


--
-- Name: changesets_work_packages_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX changesets_work_packages_ids ON changesets_work_packages USING btree (changeset_id, work_package_id);


--
-- Name: custom_fields_types_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX custom_fields_types_unique ON custom_fields_types USING btree (custom_field_id, type_id);


--
-- Name: custom_values_customized; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX custom_values_customized ON custom_values USING btree (customized_type, customized_id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON delayed_jobs USING btree (priority, run_at);


--
-- Name: documents_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX documents_project_id ON documents USING btree (project_id);


--
-- Name: enabled_modules_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enabled_modules_project_id ON enabled_modules USING btree (project_id);


--
-- Name: group_user_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX group_user_ids ON group_users USING btree (group_id, user_id);


--
-- Name: index_announcements_on_show_until_and_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_announcements_on_show_until_and_active ON announcements USING btree (show_until, active);


--
-- Name: index_attachable_journals_on_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachable_journals_on_attachment_id ON attachable_journals USING btree (attachment_id);


--
-- Name: index_attachable_journals_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachable_journals_on_journal_id ON attachable_journals USING btree (journal_id);


--
-- Name: index_attachment_journals_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachment_journals_on_journal_id ON attachment_journals USING btree (journal_id);


--
-- Name: index_attachments_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_author_id ON attachments USING btree (author_id);


--
-- Name: index_attachments_on_container_id_and_container_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_container_id_and_container_type ON attachments USING btree (container_id, container_type);


--
-- Name: index_attachments_on_created_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_created_on ON attachments USING btree (created_on);


--
-- Name: index_attachments_on_file_tsv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_file_tsv ON attachments USING gin (file_tsv);


--
-- Name: index_attachments_on_fulltext_tsv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_attachments_on_fulltext_tsv ON attachments USING gin (fulltext_tsv);


--
-- Name: index_auth_sources_on_id_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_auth_sources_on_id_and_type ON auth_sources USING btree (id, type);


--
-- Name: index_boards_on_last_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_boards_on_last_message_id ON boards USING btree (last_message_id);


--
-- Name: index_categories_on_assigned_to_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_categories_on_assigned_to_id ON categories USING btree (assigned_to_id);


--
-- Name: index_changeset_journals_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_changeset_journals_on_journal_id ON changeset_journals USING btree (journal_id);


--
-- Name: index_changesets_on_committed_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_changesets_on_committed_on ON changesets USING btree (committed_on);


--
-- Name: index_changesets_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_changesets_on_repository_id ON changesets USING btree (repository_id);


--
-- Name: index_changesets_on_repository_id_and_committed_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_changesets_on_repository_id_and_committed_on ON changesets USING btree (repository_id, committed_on);


--
-- Name: index_changesets_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_changesets_on_user_id ON changesets USING btree (user_id);


--
-- Name: index_comments_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_author_id ON comments USING btree (author_id);


--
-- Name: index_comments_on_commented_id_and_commented_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_commented_id_and_commented_type ON comments USING btree (commented_id, commented_type);


--
-- Name: index_cost_objects_on_project_id_and_updated_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cost_objects_on_project_id_and_updated_on ON cost_objects USING btree (project_id, updated_on);


--
-- Name: index_custom_fields_on_id_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_fields_on_id_and_type ON custom_fields USING btree (id, type);


--
-- Name: index_custom_fields_projects_on_custom_field_id_and_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_fields_projects_on_custom_field_id_and_project_id ON custom_fields_projects USING btree (custom_field_id, project_id);


--
-- Name: index_custom_values_on_custom_field_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_values_on_custom_field_id ON custom_values USING btree (custom_field_id);


--
-- Name: index_customizable_journals_on_custom_field_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customizable_journals_on_custom_field_id ON customizable_journals USING btree (custom_field_id);


--
-- Name: index_customizable_journals_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customizable_journals_on_journal_id ON customizable_journals USING btree (journal_id);


--
-- Name: index_design_colors_on_variable; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_design_colors_on_variable ON design_colors USING btree (variable);


--
-- Name: index_documents_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_category_id ON documents USING btree (category_id);


--
-- Name: index_documents_on_created_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_documents_on_created_on ON documents USING btree (created_on);


--
-- Name: index_enabled_modules_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enabled_modules_on_name ON enabled_modules USING btree (name);


--
-- Name: index_enumerations_on_id_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enumerations_on_id_and_type ON enumerations USING btree (id, type);


--
-- Name: index_enumerations_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enumerations_on_project_id ON enumerations USING btree (project_id);


--
-- Name: index_journals_on_activity_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_activity_type ON journals USING btree (activity_type);


--
-- Name: index_journals_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_created_at ON journals USING btree (created_at);


--
-- Name: index_journals_on_journable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_journable_id ON journals USING btree (journable_id);


--
-- Name: index_journals_on_journable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_journable_type ON journals USING btree (journable_type);


--
-- Name: index_journals_on_journable_type_and_journable_id_and_version; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_journals_on_journable_type_and_journable_id_and_version ON journals USING btree (journable_type, journable_id, version);


--
-- Name: index_journals_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_journals_on_user_id ON journals USING btree (user_id);


--
-- Name: index_meetings_on_project_id_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meetings_on_project_id_and_updated_at ON meetings USING btree (project_id, updated_at);


--
-- Name: index_member_roles_on_inherited_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_member_roles_on_inherited_from ON member_roles USING btree (inherited_from);


--
-- Name: index_member_roles_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_member_roles_on_member_id ON member_roles USING btree (member_id);


--
-- Name: index_member_roles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_member_roles_on_role_id ON member_roles USING btree (role_id);


--
-- Name: index_members_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_project_id ON members USING btree (project_id);


--
-- Name: index_members_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_members_on_user_id ON members USING btree (user_id);


--
-- Name: index_members_on_user_id_and_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_members_on_user_id_and_project_id ON members USING btree (user_id, project_id);


--
-- Name: index_menu_items_on_navigatable_id_and_title; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_items_on_navigatable_id_and_title ON menu_items USING btree (navigatable_id, title);


--
-- Name: index_menu_items_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_menu_items_on_parent_id ON menu_items USING btree (parent_id);


--
-- Name: index_message_journals_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_message_journals_on_journal_id ON message_journals USING btree (journal_id);


--
-- Name: index_messages_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_author_id ON messages USING btree (author_id);


--
-- Name: index_messages_on_board_id_and_updated_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_board_id_and_updated_on ON messages USING btree (board_id, updated_on);


--
-- Name: index_messages_on_created_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_created_on ON messages USING btree (created_on);


--
-- Name: index_messages_on_last_reply_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_last_reply_id ON messages USING btree (last_reply_id);


--
-- Name: index_news_journals_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_news_journals_on_journal_id ON news_journals USING btree (journal_id);


--
-- Name: index_news_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_news_on_author_id ON news USING btree (author_id);


--
-- Name: index_news_on_created_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_news_on_created_on ON news USING btree (created_on);


--
-- Name: index_news_on_project_id_and_created_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_news_on_project_id_and_created_on ON news USING btree (project_id, created_on);


--
-- Name: index_plaintext_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plaintext_tokens_on_user_id ON plaintext_tokens USING btree (user_id);


--
-- Name: index_principal_roles_on_principal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_principal_roles_on_principal_id ON principal_roles USING btree (principal_id);


--
-- Name: index_principal_roles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_principal_roles_on_role_id ON principal_roles USING btree (role_id);


--
-- Name: index_project_associations_on_project_a_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_associations_on_project_a_id ON project_associations USING btree (project_a_id);


--
-- Name: index_project_associations_on_project_b_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_associations_on_project_b_id ON project_associations USING btree (project_b_id);


--
-- Name: index_projects_on_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_identifier ON projects USING btree (identifier);


--
-- Name: index_projects_on_lft; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_lft ON projects USING btree (lft);


--
-- Name: index_projects_on_project_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_project_type_id ON projects USING btree (project_type_id);


--
-- Name: index_projects_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_responsible_id ON projects USING btree (responsible_id);


--
-- Name: index_projects_on_rgt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_rgt ON projects USING btree (rgt);


--
-- Name: index_projects_on_work_packages_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_work_packages_responsible_id ON projects USING btree (work_packages_responsible_id);


--
-- Name: index_queries_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_queries_on_project_id ON queries USING btree (project_id);


--
-- Name: index_queries_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_queries_on_user_id ON queries USING btree (user_id);


--
-- Name: index_relations_direct_non_hierarchy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_relations_direct_non_hierarchy ON relations USING btree (from_id) WHERE ((((((((hierarchy + relates) + duplicates) + follows) + blocks) + includes) + requires) = 1) AND (hierarchy = 0));


--
-- Name: index_relations_hierarchy_follows_scheduling; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_relations_hierarchy_follows_scheduling ON relations USING btree (to_id, hierarchy, follows, from_id) WHERE ((relates = 0) AND (duplicates = 0) AND (blocks = 0) AND (includes = 0) AND (requires = 0) AND (((((((hierarchy + relates) + duplicates) + follows) + blocks) + includes) + requires) > 0));


--
-- Name: index_relations_on_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_relations_on_count ON relations USING btree (count) WHERE (count = 0);


--
-- Name: index_relations_on_from_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_relations_on_from_id ON relations USING btree (from_id);


--
-- Name: index_relations_on_to_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_relations_on_to_id ON relations USING btree (to_id);


--
-- Name: index_relations_on_type_columns; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_relations_on_type_columns ON relations USING btree (from_id, to_id, hierarchy, relates, duplicates, blocks, follows, includes, requires);


--
-- Name: index_relations_only_hierarchy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_relations_only_hierarchy ON relations USING btree (from_id, to_id, hierarchy) WHERE ((relates = 0) AND (duplicates = 0) AND (follows = 0) AND (blocks = 0) AND (includes = 0) AND (requires = 0));


--
-- Name: index_relations_to_from_only_follows; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_relations_to_from_only_follows ON relations USING btree (to_id, follows, from_id) WHERE ((hierarchy = 0) AND (relates = 0) AND (duplicates = 0) AND (blocks = 0) AND (includes = 0) AND (requires = 0));


--
-- Name: index_repositories_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_project_id ON repositories USING btree (project_id);


--
-- Name: index_role_permissions_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_role_permissions_on_role_id ON role_permissions USING btree (role_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_session_id ON sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_updated_at ON sessions USING btree (updated_at);


--
-- Name: index_settings_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_settings_on_name ON settings USING btree (name);


--
-- Name: index_statuses_on_is_closed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statuses_on_is_closed ON statuses USING btree (is_closed);


--
-- Name: index_statuses_on_is_default; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statuses_on_is_default ON statuses USING btree (is_default);


--
-- Name: index_statuses_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statuses_on_position ON statuses USING btree ("position");


--
-- Name: index_time_entries_on_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_time_entries_on_activity_id ON time_entries USING btree (activity_id);


--
-- Name: index_time_entries_on_created_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_time_entries_on_created_on ON time_entries USING btree (created_on);


--
-- Name: index_time_entries_on_project_id_and_updated_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_time_entries_on_project_id_and_updated_on ON time_entries USING btree (project_id, updated_on);


--
-- Name: index_time_entries_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_time_entries_on_user_id ON time_entries USING btree (user_id);


--
-- Name: index_time_entry_journals_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_time_entry_journals_on_journal_id ON time_entry_journals USING btree (journal_id);


--
-- Name: index_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_user_id ON tokens USING btree (user_id);


--
-- Name: index_types_on_color_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_types_on_color_id ON types USING btree (color_id);


--
-- Name: index_user_passwords_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_passwords_on_user_id ON user_passwords USING btree (user_id);


--
-- Name: index_user_preferences_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_preferences_on_user_id ON user_preferences USING btree (user_id);


--
-- Name: index_users_on_auth_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_auth_source_id ON users USING btree (auth_source_id);


--
-- Name: index_users_on_id_and_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_id_and_type ON users USING btree (id, type);


--
-- Name: index_users_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_type ON users USING btree (type);


--
-- Name: index_users_on_type_and_login; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_type_and_login ON users USING btree (type, login);


--
-- Name: index_users_on_type_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_type_and_status ON users USING btree (type, status);


--
-- Name: index_version_settings_on_project_id_and_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_version_settings_on_project_id_and_version_id ON version_settings USING btree (project_id, version_id);


--
-- Name: index_versions_on_sharing; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_sharing ON versions USING btree (sharing);


--
-- Name: index_watchers_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watchers_on_user_id ON watchers USING btree (user_id);


--
-- Name: index_watchers_on_watchable_id_and_watchable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watchers_on_watchable_id_and_watchable_type ON watchers USING btree (watchable_id, watchable_type);


--
-- Name: index_wiki_content_journals_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_content_journals_on_journal_id ON wiki_content_journals USING btree (journal_id);


--
-- Name: index_wiki_content_versions_on_updated_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_content_versions_on_updated_on ON wiki_content_versions USING btree (updated_on);


--
-- Name: index_wiki_contents_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_contents_on_author_id ON wiki_contents USING btree (author_id);


--
-- Name: index_wiki_contents_on_page_id_and_updated_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_contents_on_page_id_and_updated_on ON wiki_contents USING btree (page_id, updated_on);


--
-- Name: index_wiki_pages_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_parent_id ON wiki_pages USING btree (parent_id);


--
-- Name: index_wiki_pages_on_wiki_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_pages_on_wiki_id ON wiki_pages USING btree (wiki_id);


--
-- Name: index_wiki_redirects_on_wiki_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wiki_redirects_on_wiki_id ON wiki_redirects USING btree (wiki_id);


--
-- Name: index_work_package_journals_on_journal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_package_journals_on_journal_id ON work_package_journals USING btree (journal_id);


--
-- Name: index_work_packages_on_assigned_to_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_packages_on_assigned_to_id ON work_packages USING btree (assigned_to_id);


--
-- Name: index_work_packages_on_author_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_packages_on_author_id ON work_packages USING btree (author_id);


--
-- Name: index_work_packages_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_packages_on_category_id ON work_packages USING btree (category_id);


--
-- Name: index_work_packages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_packages_on_created_at ON work_packages USING btree (created_at);


--
-- Name: index_work_packages_on_fixed_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_packages_on_fixed_version_id ON work_packages USING btree (fixed_version_id);


--
-- Name: index_work_packages_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_packages_on_project_id ON work_packages USING btree (project_id);


--
-- Name: index_work_packages_on_project_id_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_packages_on_project_id_and_updated_at ON work_packages USING btree (project_id, updated_at);


--
-- Name: index_work_packages_on_responsible_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_packages_on_responsible_id ON work_packages USING btree (responsible_id);


--
-- Name: index_work_packages_on_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_packages_on_status_id ON work_packages USING btree (status_id);


--
-- Name: index_work_packages_on_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_packages_on_type_id ON work_packages USING btree (type_id);


--
-- Name: index_work_packages_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_work_packages_on_updated_at ON work_packages USING btree (updated_at);


--
-- Name: index_workflows_on_new_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflows_on_new_status_id ON workflows USING btree (new_status_id);


--
-- Name: index_workflows_on_old_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflows_on_old_status_id ON workflows USING btree (old_status_id);


--
-- Name: index_workflows_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflows_on_role_id ON workflows USING btree (role_id);


--
-- Name: issue_categories_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX issue_categories_project_id ON categories USING btree (project_id);


--
-- Name: messages_board_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_board_id ON messages USING btree (board_id);


--
-- Name: messages_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_parent_id ON messages USING btree (parent_id);


--
-- Name: news_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX news_project_id ON news USING btree (project_id);


--
-- Name: projects_types_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX projects_types_project_id ON projects_types USING btree (project_id);


--
-- Name: projects_types_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX projects_types_unique ON projects_types USING btree (project_id, type_id);


--
-- Name: time_entries_issue_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX time_entries_issue_id ON time_entries USING btree (work_package_id);


--
-- Name: time_entries_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX time_entries_project_id ON time_entries USING btree (project_id);


--
-- Name: versions_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_project_id ON versions USING btree (project_id);


--
-- Name: watchers_user_id_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX watchers_user_id_type ON watchers USING btree (user_id, watchable_type);


--
-- Name: wiki_content_versions_wcid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wiki_content_versions_wcid ON wiki_content_versions USING btree (wiki_content_id);


--
-- Name: wiki_contents_page_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wiki_contents_page_id ON wiki_contents USING btree (page_id);


--
-- Name: wiki_pages_wiki_id_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX wiki_pages_wiki_id_slug ON wiki_pages USING btree (wiki_id, slug);


--
-- Name: wiki_pages_wiki_id_title; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wiki_pages_wiki_id_title ON wiki_pages USING btree (wiki_id, title);


--
-- Name: wiki_redirects_wiki_id_title; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wiki_redirects_wiki_id_title ON wiki_redirects USING btree (wiki_id, title);


--
-- Name: wikis_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wikis_project_id ON wikis USING btree (project_id);


--
-- Name: wkfs_role_type_old_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX wkfs_role_type_old_status ON workflows USING btree (role_id, type_id, old_status_id);


--
-- Name: work_package_journal_on_burndown_attributes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX work_package_journal_on_burndown_attributes ON work_package_journals USING btree (fixed_version_id, status_id, project_id, type_id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('0'),
('20100528100562'),
('20110211160100'),
('20110215143061'),
('20110817142220'),
('20111014073606'),
('20111114124552'),
('20111605171865'),
('20120319095930'),
('20120319135006'),
('20120529090411'),
('20120605121861'),
('20120731091543'),
('20120731135140'),
('20120802152122'),
('20120809131659'),
('20120828171423'),
('20121004054229'),
('20121022124254'),
('20121030111651'),
('20121101111303'),
('20121114100641'),
('20130204140624'),
('20130315124655'),
('20130325165622'),
('20130409133700'),
('20130409133701'),
('20130409133702'),
('20130409133703'),
('20130409133704'),
('20130409133705'),
('20130409133706'),
('20130409133707'),
('20130409133708'),
('20130409133709'),
('20130409133710'),
('20130409133711'),
('20130409133712'),
('20130409133713'),
('20130409133714'),
('20130409133715'),
('20130409133717'),
('20130409133718'),
('20130409133719'),
('20130409133720'),
('20130409133721'),
('20130409133722'),
('20130409133723'),
('20130529145329'),
('20130611154020'),
('20130612104243'),
('20130612120042'),
('20130613075253'),
('20130619081234'),
('20130620082322'),
('20130625094113'),
('20130625094710'),
('20130625124242'),
('20130628092725'),
('20130709084751'),
('20130710145350'),
('20130717134318'),
('20130719133922'),
('20130722154555'),
('20130723092240'),
('20130723134527'),
('20130724143418'),
('20130729114110'),
('20130731151542'),
('20130806075000'),
('20130807081927'),
('20130807082645'),
('20130807083715'),
('20130807083716'),
('20130807084417'),
('20130807084708'),
('20130807085108'),
('20130807085245'),
('20130807085430'),
('20130807085604'),
('20130807085714'),
('20130807141542'),
('20130813062401'),
('20130813062513'),
('20130813062523'),
('20130814130142'),
('20130814131242'),
('20130822113942'),
('20130828093647'),
('20130829084747'),
('20130903172842'),
('20130904181242'),
('20130916094339'),
('20130916094369'),
('20130916094370'),
('20130916123916'),
('20130917101922'),
('20130917122118'),
('20130917131710'),
('20130918084158'),
('20130918084919'),
('20130918111753'),
('20130918160542'),
('20130918180542'),
('20130919092624'),
('20130919105841'),
('20130919145142'),
('20130920081120'),
('20130920081135'),
('20130920085055'),
('20130920090201'),
('20130920090641'),
('20130920092800'),
('20130920093823'),
('20130920094524'),
('20130920095747'),
('20130920142714'),
('20130920150143'),
('20130924091342'),
('20130924093842'),
('20130924114042'),
('20130925090243'),
('20131001075217'),
('20131001105659'),
('20131001132542'),
('20131004141959'),
('20131007062401'),
('20131009083648'),
('20131015064141'),
('20131015121430'),
('20131016075650'),
('20131017064039'),
('20131018134525'),
('20131018134530'),
('20131018134545'),
('20131018134590'),
('20131024115743'),
('20131024140048'),
('20131031170857'),
('20131101125921'),
('20131108124300'),
('20131114132911'),
('20131115155147'),
('20131126112911'),
('20131127120534'),
('20131202094511'),
('20131210113056'),
('20131216171110'),
('20131219084934'),
('20140113132617'),
('20140122161742'),
('20140127134733'),
('20140129103924'),
('20140203141127'),
('20140207134248'),
('20140311120609'),
('20140320140001'),
('20140411142338'),
('20140414141459'),
('20140429152018'),
('20140430125956'),
('20140602112515'),
('20140610125207'),
('20141215104802'),
('20150116095004'),
('20150623151337'),
('20150629075221'),
('20150716133712'),
('20150716163704'),
('20150729145732'),
('20150819143300'),
('20150820133700'),
('20150827133700'),
('20151005113102'),
('20151028063433'),
('20151116110245'),
('20160125143638'),
('20160419103544'),
('20160503150449'),
('20160504064737'),
('20160504070128'),
('20160726090624'),
('20160803094931'),
('20160824121151'),
('20160829225633'),
('20160907113604'),
('20160913081236'),
('20160913125802'),
('20160914124514'),
('20160926102618'),
('20161017102547'),
('20161025135400'),
('20161102160032'),
('20161116130657'),
('20161213191919'),
('20161219134700'),
('20170116105342'),
('20170117112648'),
('20170222094032'),
('20170308120915'),
('20170330084810'),
('20170404110156'),
('20170407074032'),
('20170411065946'),
('20170418064453'),
('20170420082944'),
('20170421071136'),
('20170421071137'),
('20170602073043'),
('20170614131555'),
('20170703075208'),
('20170705134348'),
('20170818063404'),
('20170829095701'),
('20170911111617'),
('20171106074835'),
('20171129145631'),
('20180105130053'),
('20180108132929'),
('20180117065255'),
('20180122135443');


