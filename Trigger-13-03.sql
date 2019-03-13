create trigger Trex_2 before insert or update or delete
on itens_consumo for each row 
declare 
    quantidadeProduto produtos.pro_qtd%Type;
    precoDoProduto produtos.pro_preco%Type;
    dataDoConsumo consumo.con_data%Type;
    valorDaPromocao promocao.promo_valor%Type;
begin

    --se tiver sendo feita uma inserção
    if inserting then 
        --selecione a quantidade do produto a ser consumido 
        select pro_qtd,pro_preco into quantidaProduto,precoDoProduto from produtos p where p.pro_cod = :new.pro_cod;
        --se a tem quantidade suficiente em estoque( quantidadeAtual >=0 quantidadeAtual - quantidadeConsumida)
        if :quantidadeProduto - :new.ite_qtd >= 0 then
            
            begin 
                --selecione a data do consumo (nesse caso a data sempre vai retornar um valor, se nao é impossivel fazer o insert)
                select con_data into dataDoConsumo from consumo where con_cod = :new.con_cod;
                --selecione o valor do produto quando ele esta em promocao (quando a data de consumo esta entre as datas de promocao)
                select promo_valor into valorDaPromocao from promocao where pro_cod = :new.pro_cod and  dataDeConsumo  between promo_dataInicio AND promo_dataFim;
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
            raise_aplication_error(-20500,'quantidade de produto em estoque insuficiente');

        end if;
    end if;



end;