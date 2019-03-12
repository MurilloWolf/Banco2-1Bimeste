use bd2t;

create table clientes(
    cli_cod integer not null,
    cli_email varchar(40),
    cli_nome varchar(50) not null,

    constraint Pk_clientes primary key (cli_cod)
);

create table locais (
    loc_cod integer not null, 
    loc_descricao varchar(50),

    constraint Pk_locais primary key (loc_cod)
);

create table produtos (
    pro_cod integer not null,
    pro_descricao varchar(50),
    pro_qtd integer,
    pro_preco numeric (5,2),

    constraint Pk_produtos primary key (pro_cod)
);

create table promocao(
    pro_datainicio date not null,
    pro_cod integer not null,
    pro_datafim date,
    pro_valor numeric (5,2),

    constraint Pk_promocao primary key (pro_datainicio,pro_cod),
    constraint Fk_prod_promocao foreign key (pro_cod) references produtos (pro_cod)
);

create table categoria_quartos (
    cat_cod integer not null,
    cat_descricao varchar(50),
    cat_valor numeric (5,2),
    cat_capacidade integer not null,

    constraint Pk_categoria_quarto primary key (cat_cod)
);

create table quartos (
    qua_cod integer not null,
    cat_cod integer,

    constraint Pk_quartos primary key (qua_cod),
    constraint Fk_quartos_categoria foreign key (cat_cod) references categoria_quartos (cat_cod)
);

create table reservas (
    res_cod integer not null,
    res_qtdparcelas integer,
    res_qtspessoas integer,
    res_status varchar(15),
    res_dtsaida date, 
    res_dtentrada date,
    
    cli_cod integer,
    cat_cod integer,
    qua_cod integer,

    constraint Pk_reservar primary key (res_cod),
    constraint Fk_reserva_cliente foreign key (cli_cod) references clientes (cli_cod),
    constraint Fk_reserva_categoria foreign key (cat_cod) references categoria_quartos (cat_cod),
    constraint Fk_reserva_quartos foreign key (qua_cod) references quartos (qua_cod)
);

create table parcelas (
    par_cod integer not null,
    res_cod integer not null,
    par_valor numeric (5,2), 
    par_dtvencimento date,
    par_dtpagamento date,

    constraint Pk_parcelas primary key(par_cod,res_cod),
    constraint Fk_parcelas_reservas foreign key (res_cod) references reservas (res_cod)
);

create table consumo (
    con_cod integer not null,
    con_data date, 
    loc_cod integer,
    res_cod integer,

    constraint Pk_consumo primary key (con_cod),
    constraint Fk_consumo_reservas foreign key (res_cod) references reservas (res_cod),
    constraint Fk_consumo_locais foreign key (loc_cod) references locais (loc_cod)

);

create table intes_consumo (
    pro_cod integer not null,
    con_cod integer not null,
    ite_preco numeric (5,2),
    ite_qtd integer,

    constraint Pk_itens_consumo primary key (pro_cod,con_cod),
    constraint Fk_itens_consumo  foreign key (con_cod) references consumo (con_cod),
    constraint Fk_itens_produtos foreign key (pro_cod) references produtos (pro_cod)
);