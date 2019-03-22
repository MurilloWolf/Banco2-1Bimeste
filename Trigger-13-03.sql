create trigger Trex_2 before insert or update or delete
on itens_consumo for each row 
declare 
    novaQauntidadeEmEstoque produtos.pro_qtd%Type;
    quantidadeProduto produtos.pro_qtd%Type;
    precoDoProduto produtos.pro_preco%Type;
    dataDoConsumo consumo.con_data%Type;
    valorDaPromocao promocao.pro_valor%Type;
begin

    --se tiver sendo feita uma inserção
    if inserting then 
        --selecione a quantidade do produto a ser consumido 
        select pro_qtd,pro_preco into quantidadeProduto,precoDoProduto from produtos p where p.pro_cod = :new.pro_cod;
        --se a tem quantidade suficiente em estoque( quantidadeAtual >=0 quantidadeAtual - quantidadeConsumida)
        if :quantidadeProduto - :new.ite_qtd >= 0 then
            
            begin 
                --selecione a data do consumo (nesse caso a data sempre vai retornar um valor, se nao é impossivel fazer o insert)
                select con_data into dataDoConsumo from consumo where con_cod = :new.con_cod;
                --selecione o valor do produto quando ele esta em promocao (quando a data de consumo esta entre as datas de promocao)
                select pro_valor into valorDaPromocao from promocao where pro_cod = :new.pro_cod and  dataDoConsumo  between pro_dataInicio AND pro_dataFim;
                --betwenn -> dataDeConsumo = between (promo_dataInicio,promo_dataFIm);
                :new.ite_preco := valorDaPromocao;
                
            --caso o produto nao esteja em promocao, sera retornado NO_DATA_FOUND
            exception
                when NO_DATA_FOUND then
                    --se nao tiver promocao do produto o preco a ser inserido na tabela sera o valor normal do proprio produto
                    :new.ite_preco := precoDoProduto;

            end; 

            --após identificar o valor do produto, atualize a quantidade do produto no estoque
            update produtos set pro_qtd = pro_qtd - :new.ite_qtd where pro_cod =  :new.pro_cod;
        
        --se nao tiver produto suficiente em etoque 
        else
            RAISE_APPLICATION_ERROR( -20500,'quantidade de produto em estoque insuficiente');

        end if;
    end if;

    --se estiver atualizando 
    if updating then 

        --buscar a quantidade de produto em estoque 
        select pro_qtd into quantidadeProduto from produtos p where p.pro_cod = :new.pro_cod;

        --se nao for uma quantidade negativa 
        if( :new.ite_qtd >= 0 ) then   
            
            --calcular a nova quantidade que deve estar em estoque
            novaQauntidadeEmEstoque := :old.ite_qtd - :new.ite_qtd;
            quantidadeProduto := quantidadeProduto + novaQauntidadeEmEstoque;

            --se nao for uma quantidade negativa
            if(quantidadeProduto >=0) then
                --atualizar q quantidade de produto em estoque
                update produtos set pro_qtd = quantidadeProduto where pro_cod = :new.pro_cod;
                
            else
            --se for uma quantidade negativa Erro
                RAISE_APPLICATION_ERROR(-20500, 'a quantidade em estoque nao pode ser negativa');

            end if;
        
        else 
            
            RAISE_APPLICATION_ERROR(-20500, 'a quantidade em estoque nao pode ser negativa');


        end if;


    end if;

    if deleting then
        
        select pro_qtd into quantidadeProduto from produtos p where p.pro_cod = :new.pro_cod;

        quantidadeProduto := quantidadeProduto + :old.ite_qtd;
        update produtos set pro_qtd = quantidadeProduto where pro_cod = :old.pro_cod;



    end if;



end;


create trigger Trex_3 before update
on reservas for each row
declare 
    numeroDoQuarto integer;
    pragma AUTONOMOUS_TRANSACTION;
begin
    --se ele estiver fazendo check-in
    if ( :new.res_status == 'h' or :new.res_status == 'H') then
    
        begin
            --selecionar os numeros dos quartos cuja a data de saida diferente de null e menor do que a data e hora atual(SYSDATE)
            --e selecionar o numero do quarto que esteja de acordo com a categoria da reserva (cat_cod == :new.cat_cod)
            select q.qua_cod into numeroDoquarto from RESERVAS r , QUARTOS q where ROWNUM = 1 and q.cat_cod = :new.cat_cod AND
                                                                         r.res_dtSaida is not null and r.res_dtSaida < SYSDATE;
            update reservas set qua_cod = numeroDoQuarto where res_cod = :new.res_cod;
            exception
                when NO_DATA_FOUND then 
                RAISE_APPLICATION_ERROR(-20500,'nenhum quarto livre foi encontrado');
        end;
    end if;
    
    commit;
end;

create or replace trigger Trex_4 after insert on reservas for each row
declare 
    precoDoQuarto categoria_quartos.cat_valor%Type;
    dataDeVencimento date; 
    contadorDeParcelas integer := 0;
begin 
    select cat_valor into precoDoQuarto from categoria_quartos where cat_cod = :new.cat_cod;
  
    if(:new.res_qtdparcelas > 1) then

        precoDoQuarto := precoDoQuarto / :new.res_qtdparcelas;
        dataDeVencimento := :new.res_dtsaida;

        while contadorDeParcelas < :new.res_qtdparcelas loop
            
            insert into parcelas (par_cod,res_cod,par_valor,par_dtVencimento,par_dtPagamento) values (seq_cod_parcelas.nextval,:new.res_cod,precoDoQuarto,dataDeVencimento,null);
            dataDeVencimento := dataDeVencimento + 30;
            contadorDeParcelas := contadorDeParcelas + 1;
        end loop;
    else
        
        insert into parcelas (par_cod,res_cod,par_valor,par_dtVencimento,par_dtPagamento) values (seq_cod_parcelas.nextval,:new.res_cod,precoDoQuarto,dataDeVencimento,:new.res_dtSaida);

    end if;

end;

create or replace trigger Trex_5 before update on categoria_quartos for each row
declare 
    resultado integer;
begin 
    select count (res_cod) into resultado from reservas where UPPER( res_status ) = 'P' and :new.cat_capacidade < res_qtdpessoas;
   
    if( resultado > 0 ) then
        RAISE_APPLICATION_ERROR (-20001,'não é possivel alterar a quantidade de pessoas do quarto');
    end if;

end;

create or replace trigger Trex_6 before delete on promocao for each row
declare 
    resultado integer;
    dataDeInicio date;
    dataDeFim date;
begin 
    select pro_datainicio, pro_datafim into dataDeInicio, dataDeFim from promocao where pro_cod = :old.pro_cod;
    select count (con_cod) into resultado from consumo where con_data between dataDeInicio and dataDeFim;

    if(resultado > 0) then
        RAISE_APPLICATION_ERROR(-20001,'promocao nao pode ser excluida');
    end if;



end;