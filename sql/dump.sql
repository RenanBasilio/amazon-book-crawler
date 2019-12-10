--
-- PostgreSQL database dump
--

-- Dumped from database version 10.6
-- Dumped by pg_dump version 10.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: insere_livros(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insere_livros() RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO produtos(titulo, isbn, descricao)
    (
      SELECT DISTINCT ON (isbn) title, isbn, authors
      FROM products_temp
      WHERE isbn NOT IN (SELECT isbn FROM produtos)
    ) ;

  WITH t1 AS (
          SELECT pt.id AS produto_fk
          FROM products_temp pt
            JOIN produtos p ON pt.isbn = p.isbn
       )
  DELETE FROM url
    USING t1
    WHERE url.produto_fk = t1.produto_fk;

  INSERT INTO url(produto_fk, moeda_fk, url)
    (
      SELECT DISTINCT ON (p.id) p.id, (SELECT id FROM moedas WHERE moedas.codigo = 'BRL'), product_url
      FROM products_temp pt
        JOIN produtos p ON pt.isbn = p.isbn
    );

  INSERT INTO url(produto_fk, moeda_fk, url)
    (
      SELECT DISTINCT ON (p.id) p.id, (SELECT id FROM moedas WHERE moedas.codigo = 'USD'), lt.url
      FROM list_us_temp lt
        JOIN produtos p ON lt.isbn = p.isbn
    );

    DROP TABLE IF EXISTS products_temp_excluidos;
    CREATE TEMPORARY TABLE products_temp_excluidos AS (SELECT * FROM products_temp);
--     DELETE FROM products_temp;
    RETURN 'Ok!';
END;
$$;


ALTER FUNCTION public.insere_livros() OWNER TO postgres;

--
-- Name: insere_precos(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insere_precos() RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
  INSERT INTO precos(produto_fk, moeda_fk, valor, data, horario, posicao)
    (
      SELECT u.produto_fk,
             CASE WHEN value ILIKE 'R$%' THEN (SELECT id FROM moedas WHERE codigo = 'BRL')
                  WHEN value ILIKE '$%' THEN (SELECT id FROM moedas WHERE codigo = 'USD')
             END AS moeda,
             translate(replace(value,',','.'),'R$','')::FLOAT, now()::DATE, now()::TIME, pt.position
      FROM prices_temp pt
        JOIN url u ON u.url = pt.url
      WHERE value != '0'
    ) ;

    DROP TABLE IF EXISTS prices_temp_excluidos;
    CREATE TEMPORARY TABLE prices_temp_excluidos AS (SELECT * FROM prices_temp);
--      DELETE FROM prices_temp;
    RETURN 'Ok!';
END;
$_$;


ALTER FUNCTION public.insere_precos() OWNER TO postgres;

--
-- Name: insere_precos(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insere_precos(_country text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
BEGIN
  INSERT INTO precos(produto_fk, moeda_fk, valor, data, horario, posicao)
    (
      SELECT u.produto_fk, (SELECT id FROM moedas WHERE pais = _country), translate(replace(value,',','.'),'R$',''), now()::DATE, now()::TIME, pt.position
      FROM prices_temp pt
        JOIN url u ON u.url = pt.url
    ) ;


    DROP TABLE IF EXISTS prices_temp_excluidos;
    CREATE TEMPORARY TABLE prices_temp_excluidos AS (SELECT * FROM prices_temp);
    DELETE FROM prices_temp;
    RETURN 'Ok!';
END;
$_$;


ALTER FUNCTION public.insere_precos(_country text) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cambio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cambio (
    id integer NOT NULL,
    moeda_origem_fk integer NOT NULL,
    moeda_destino_fk integer NOT NULL,
    taxa double precision NOT NULL
);


ALTER TABLE public.cambio OWNER TO postgres;

--
-- Name: cambio_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cambio_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cambio_id_seq OWNER TO postgres;

--
-- Name: cambio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cambio_id_seq OWNED BY public.cambio.id;


--
-- Name: list_us_backup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.list_us_backup (
    isbn character varying(1024),
    url character varying(1024)
);


ALTER TABLE public.list_us_backup OWNER TO postgres;

--
-- Name: list_us_temp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.list_us_temp (
    isbn character varying(1024),
    url character varying(1024)
);


ALTER TABLE public.list_us_temp OWNER TO postgres;

--
-- Name: produtos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.produtos (
    id integer NOT NULL,
    titulo text NOT NULL,
    isbn character varying(255) NOT NULL,
    descricao character varying(1024),
    data_publicacao date,
    categoria character varying(1024)
);


ALTER TABLE public.produtos OWNER TO postgres;

--
-- Name: url; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.url (
    id integer NOT NULL,
    produto_fk integer NOT NULL,
    moeda_fk integer NOT NULL,
    url character varying(2048) NOT NULL
);


ALTER TABLE public.url OWNER TO postgres;

--
-- Name: listagem; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.listagem AS
 SELECT pt.isbn,
    u.url
   FROM (public.produtos pt
     JOIN public.url u ON ((u.produto_fk = pt.id)))
  ORDER BY pt.isbn;


ALTER TABLE public.listagem OWNER TO postgres;

--
-- Name: moedas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.moedas (
    id integer NOT NULL,
    codigo character varying(1024) NOT NULL,
    pais character varying(1024)
);


ALTER TABLE public.moedas OWNER TO postgres;

--
-- Name: moedas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.moedas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.moedas_id_seq OWNER TO postgres;

--
-- Name: moedas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.moedas_id_seq OWNED BY public.moedas.id;


--
-- Name: precos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.precos (
    id integer NOT NULL,
    produto_fk integer NOT NULL,
    moeda_fk integer NOT NULL,
    valor double precision NOT NULL,
    data date NOT NULL,
    horario time without time zone NOT NULL,
    posicao integer
);


ALTER TABLE public.precos OWNER TO postgres;

--
-- Name: precos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.precos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.precos_id_seq OWNER TO postgres;

--
-- Name: precos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.precos_id_seq OWNED BY public.precos.id;


--
-- Name: prices_temp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prices_temp (
    id integer NOT NULL,
    url character varying(255) NOT NULL,
    value character varying(255) NOT NULL,
    "position" integer
);


ALTER TABLE public.prices_temp OWNER TO postgres;

--
-- Name: prices_temp_backup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prices_temp_backup (
    id integer,
    url character varying(255),
    value character varying(255),
    "position" integer
);


ALTER TABLE public.prices_temp_backup OWNER TO postgres;

--
-- Name: prices_temp_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prices_temp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.prices_temp_id_seq OWNER TO postgres;

--
-- Name: prices_temp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prices_temp_id_seq OWNED BY public.prices_temp.id;


--
-- Name: products_backup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products_backup (
    id integer,
    title character varying(2056),
    product_url character varying(2056),
    isbn character varying(2056),
    authors character varying(2056)
);


ALTER TABLE public.products_backup OWNER TO postgres;

--
-- Name: products_temp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products_temp (
    id integer NOT NULL,
    title character varying(2056),
    product_url character varying(2056),
    isbn character varying(2056),
    authors character varying(2056)
);


ALTER TABLE public.products_temp OWNER TO postgres;

--
-- Name: products_temp_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.products_temp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.products_temp_id_seq OWNER TO postgres;

--
-- Name: products_temp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.products_temp_id_seq OWNED BY public.products_temp.id;


--
-- Name: produtos_convertido; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.produtos_convertido AS
 WITH t1 AS (
         SELECT DISTINCT ON (prod.isbn) prod.titulo,
            prod.isbn,
            prod.descricao AS autor,
            pr.posicao,
            first_value(pr.valor) OVER (PARTITION BY prod.isbn ORDER BY pr.data DESC) AS preco_real,
            first_value(pd.valor) OVER (PARTITION BY prod.isbn ORDER BY pd.data DESC) AS preco_dolar,
            (first_value(pd.valor) OVER (PARTITION BY prod.isbn ORDER BY pd.data DESC) * c.taxa) AS preco_convertido,
            ur.url AS link_real,
            ud.url AS link_dolar
           FROM (((((((public.produtos prod
             JOIN public.precos pr ON ((pr.produto_fk = prod.id)))
             JOIN public.moedas mr ON ((pr.moeda_fk = mr.id)))
             JOIN public.cambio c ON ((mr.id = c.moeda_destino_fk)))
             JOIN public.moedas md ON ((c.moeda_origem_fk = md.id)))
             JOIN public.precos pd ON ((pd.produto_fk = prod.id)))
             LEFT JOIN public.url ur ON (((ur.produto_fk = prod.id) AND (ur.moeda_fk = mr.id))))
             LEFT JOIN public.url ud ON (((ud.produto_fk = prod.id) AND (ud.moeda_fk = md.id))))
          WHERE ((pr.moeda_fk = 1) AND (pd.moeda_fk = 2))
        )
 SELECT t1.titulo,
    t1.isbn,
    t1.autor,
    t1.posicao,
    t1.preco_real,
    t1.preco_dolar,
    t1.preco_convertido,
    t1.link_real,
    t1.link_dolar,
    ((100)::double precision * ((t1.preco_real / t1.preco_convertido) - (1)::double precision)) AS diferenca
   FROM t1
  WHERE (t1.preco_real < ((2)::double precision * t1.preco_convertido))
  ORDER BY ((100)::double precision * ((t1.preco_real / t1.preco_convertido) - (1)::double precision)) DESC
  WITH NO DATA;


ALTER TABLE public.produtos_convertido OWNER TO postgres;

--
-- Name: produtos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.produtos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.produtos_id_seq OWNER TO postgres;

--
-- Name: produtos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.produtos_id_seq OWNED BY public.produtos.id;


--
-- Name: url_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.url_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.url_id_seq OWNER TO postgres;

--
-- Name: url_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.url_id_seq OWNED BY public.url.id;


--
-- Name: cambio id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cambio ALTER COLUMN id SET DEFAULT nextval('public.cambio_id_seq'::regclass);


--
-- Name: moedas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.moedas ALTER COLUMN id SET DEFAULT nextval('public.moedas_id_seq'::regclass);


--
-- Name: precos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.precos ALTER COLUMN id SET DEFAULT nextval('public.precos_id_seq'::regclass);


--
-- Name: prices_temp id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prices_temp ALTER COLUMN id SET DEFAULT nextval('public.prices_temp_id_seq'::regclass);


--
-- Name: products_temp id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products_temp ALTER COLUMN id SET DEFAULT nextval('public.products_temp_id_seq'::regclass);


--
-- Name: produtos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produtos ALTER COLUMN id SET DEFAULT nextval('public.produtos_id_seq'::regclass);


--
-- Name: url id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.url ALTER COLUMN id SET DEFAULT nextval('public.url_id_seq'::regclass);


--
-- Name: cambio cambio_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cambio
    ADD CONSTRAINT cambio_pk PRIMARY KEY (id);


--
-- Name: moedas moedas_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.moedas
    ADD CONSTRAINT moedas_pk PRIMARY KEY (id);


--
-- Name: precos precos_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.precos
    ADD CONSTRAINT precos_pk PRIMARY KEY (id);


--
-- Name: prices_temp prices_temp_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prices_temp
    ADD CONSTRAINT prices_temp_pk PRIMARY KEY (id);


--
-- Name: products_temp products_temp_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products_temp
    ADD CONSTRAINT products_temp_pk PRIMARY KEY (id);


--
-- Name: produtos produtos_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produtos
    ADD CONSTRAINT produtos_pk PRIMARY KEY (id);


--
-- Name: url url_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.url
    ADD CONSTRAINT url_pk PRIMARY KEY (id);


--
-- Name: cambio cambio_fk0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cambio
    ADD CONSTRAINT cambio_fk0 FOREIGN KEY (moeda_origem_fk) REFERENCES public.moedas(id);


--
-- Name: cambio cambio_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cambio
    ADD CONSTRAINT cambio_fk1 FOREIGN KEY (moeda_destino_fk) REFERENCES public.moedas(id);


--
-- Name: precos precos_fk0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.precos
    ADD CONSTRAINT precos_fk0 FOREIGN KEY (produto_fk) REFERENCES public.produtos(id);


--
-- Name: precos precos_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.precos
    ADD CONSTRAINT precos_fk1 FOREIGN KEY (moeda_fk) REFERENCES public.moedas(id);


--
-- Name: url url_fk0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.url
    ADD CONSTRAINT url_fk0 FOREIGN KEY (produto_fk) REFERENCES public.produtos(id);


--
-- Name: url url_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.url
    ADD CONSTRAINT url_fk1 FOREIGN KEY (moeda_fk) REFERENCES public.moedas(id);


--
-- PostgreSQL database dump complete
--

