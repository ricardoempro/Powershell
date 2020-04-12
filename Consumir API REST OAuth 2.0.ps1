[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$urlBase = "url"

$credenciais = @{
    email= "login"
    password= "xxxxx"
} | ConvertTo-Json

$credenciais

$retornoLogin = Invoke-RestMethod  -Uri ($urlBase + "auth/v1/users/login") -Method POST -ContentType "application/json" -Body $credenciais

$retornoLogin

$idCliente = "61585865060642"
$idContrato = "84200bfb-81b8-41f8-8158-8ea7c75a9e2c"

$dataInicio = “2019-10-22T00:00:00.000Z”
$dataFim = “2019-10-22T23:59:59.999Z”

$periodo = "from_data_hora="+$dataInicio+"&to_data_hora="+$dataFim


if ($retornoLogin.token) {

    $headers = @{
        Authorization = "Bearer " + $retornoLogin.token
    }

    $headers

    $url_API_Transacao = ($urlBase + "p2m/v1/clientes/" + $idCliente + "/contratos/" + $idContrato + "/transacoes?" + $periodo + "&page=1&page_size=30")
        
    $retornoTransacao = Invoke-RestMethod  -Uri $url_API_Transacao -Headers $headers -Method GET -ContentType "application/json"

    $retornoTransacao

    if ($retornoTransacao.pagination) {
        
        $totalPaginas = $retornoTransacao.pagination.total_pages
        $transacoes = $retornoTransacao.data

        For ($i=2; $i -le $totalPaginas; $i++) {
            sleep 2

            $url_API_Transacao = ($urlBase + "p2m/v1/clientes/" + $idCliente + "/contratos/" + $idContrato + "/transacoes?" + $periodo + "&page=" + $i +"&page_size=30")
            
            $retPagTransacao = Invoke-RestMethod  -Uri $url_API_Transacao -Headers $headers -Method GET -ContentType "application/json"

            For($y = 0; $y -lt $retPagTransacao.data.Length; $y++) {

                $transacoes += $retPagTransacao.data[$y]
            }
            
        }
    } else {
        $transacoes = $retornoTransacao.data
    }


    sleep 3

    $url_API_Liquidacao = ($urlBase + "p2m/v1/clientes/" + $idCliente + "/contratos/" + $idContrato + "/liquidacoes?" + $periodo + "&page=1&page_size=30")

    $retornoLiquidacao = Invoke-RestMethod  -Uri $url_API_Liquidacao -Headers $headers -Method GET -ContentType "application/json"

    $retornoLiquidacao

    if ($retornoLiquidacao.pagination) {
        
        $totalPaginas = $retornoLiquidacao.pagination.total_pages
        $liquidacoes = $retornoLiquidacao.data

        For ($i=2; $i -le $totalPaginas; $i++) {
            sleep 2

            $url_API_Liquidacao = ($urlBase + "p2m/v1/clientes/" + $idCliente + "/contratos/" + $idContrato + "/liquidacoes?" + $periodo + "&page=" + $i + "&page_size=30")
            
            $retPagLiquidacao = Invoke-RestMethod  -Uri $url_API_Liquidacao -Headers $headers -Method GET -ContentType "application/json"

            For($y = 0; $y -lt $retPagLiquidacao.data.Length; $y++) {

                $liquidacoes += $retPagLiquidacao.data[$y]
            }
            
        }
    } else {
        $liquidacoes = $retornoLiquidacao.data
    }

    sleep 3

    $url_API_Cancelados = ($urlBase + "p2m/v1/clientes/" + $idCliente + "/contratos/" + $idContrato + "/transacoes?" + $periodo + "&status=Cancelado&page=1&page_size=30")
        
    $retornoCancelados = Invoke-RestMethod  -Uri $url_API_Cancelados -Headers $headers -Method GET -ContentType "application/json"

    $retornoCancelados

    if ($retornoCancelados.pagination) {
        
        $totalPaginas = $retornoCancelados.pagination.total_pages
        $cancelados = $retornoCancelados.data

        For ($i=2; $i -le $totalPaginas; $i++) {
            sleep 2

            $url_API_Cancelados = ($urlBase + "p2m/v1/clientes/" + $idCliente + "/contratos/" + $idContrato + "/transacoes?" + $periodo + "&status=Cancelado&page=" + $i + "&page_size=30")
            
            $retPagCancelados = Invoke-RestMethod  -Uri $url_API_Cancelados -Headers $headers -Method GET -ContentType "application/json"

            For($y = 0; $y -lt $retPagCancelados.data.Length; $y++) {

                $cancelados += $retPagCancelados.data[$y]
            }
            
        }
    } else {
        $cancelados = $retornoCancelados.data
    }
        

    $objConciliacao = @{
        autorizadora = "iti"
        versao = "001.0a"
        id_cliente = $idCliente
        data_pesquisada = $dataInicio.Substring(0,10).Replace("-","")
        data_geracao = Get-Date -Format "yyyyMMdd"
        hora_geracao = Get-Date -Format "HHmmss" 
        geracao_agendada = $FALSE
        contratos = @{
            $idContrato = @{
                liquidacoes = $liquidacoes
                transacoes = $transacoes
                cancelamentos = $cancelados
            }
        }
    }

    $objConciliacao

    $textoObjConciliacao = $objConciliacao | ConvertTo-Json -Depth 4 
     
    out-file -filepath C:\Users\rferrene\Documents\ConciliacaoCompleto_$idCliente.json -inputobject $textoObjConciliacao -Encoding utf8  

    
    $csvTransacao = "type;id_transacao;valor_mdr;valor_liquido;valor_bruto;data_hora;data_cancelamento;id_liquidacao;data_liquidacao;id_loja;id_caixa;id_carrinho;id_liquidacao_cancelamento;status`n"

    For($y = 0; $y -lt $transacoes.Length; $y++) {
        $csvTransacao += "T;"+$transacoes[$y].id_transacao+";"+
                         $transacoes[$y].valor_mdr+";"+
                         $transacoes[$y].valor_liquido+";"+
                         $transacoes[$y].valor_bruto+";"+
                         $transacoes[$y].data_hora+";"+
                         $transacoes[$y].data_cancelamento+";"+
                         $transacoes[$y].id_liquidacao+";"+
                         $transacoes[$y].data_liquidacao+";"+
                         $transacoes[$y].id_loja+";"+
                         $transacoes[$y].id_caixa+";"+
                         $transacoes[$y].id_carrinho+";"+
                         $transacoes[$y].id_liquidacao_cancelamento+";"+
                         $transacoes[$y].status+";`n"
    }

    $csvCancelador = "type;id_transacao;valor_mdr;valor_liquido;valor_bruto;data_hora;data_cancelamento;id_liquidacao;data_liquidacao;id_loja;id_caixa;id_carrinho;id_liquidacao_cancelamento;status`n"

    For($y = 0; $y -lt $cancelados.Length; $y++) {
        $csvCancelador += "C;"+$cancelados[$y].id_transacao+";"+
                         $cancelados[$y].valor_mdr+";"+
                         $cancelados[$y].valor_liquido+";"+
                         $cancelados[$y].valor_bruto+";"+
                         $cancelados[$y].data_hora+";"+
                         $cancelados[$y].data_cancelamento+";"+
                         $cancelados[$y].id_liquidacao+";"+
                         $cancelados[$y].data_liquidacao+";"+
                         $cancelados[$y].id_loja+";"+
                         $cancelados[$y].id_caixa+";"+
                         $cancelados[$y].id_carrinho+";"+
                         $cancelados[$y].id_liquidacao_cancelamento+";"+
                         $cancelados[$y].status+";`n"
    }


    $csvLiquidacao = "type;id_liquidacao;valor_bruto_transacoes;valor_cancelado_transacoes;valor_mdr_transacoes;valor_liquido_transacoes;data_liquidacao;agencia;numero_banco;conta_corrente;digito_verificador`n"
    For($y = 0; $y -lt $liquidacoes.Length; $y++) {
        $csvLiquidacao += "L;"+$liquidacoes[$y].id_liquidacao+";"+
                         $liquidacoes[$y].valor_bruto_transacoes+";"+
                         $liquidacoes[$y].valor_cancelado_transacoes+";"+
                         $liquidacoes[$y].valor_mdr_transacoes+";"+
                         $liquidacoes[$y].valor_liquido_transacoes+";"+
                         $liquidacoes[$y].data_liquidacao+";"+
                         $liquidacoes[$y].agencia+";"+
                         $liquidacoes[$y].numero_banco+";"+
                         $liquidacoes[$y].conta_corrente+";"+
                         $liquidacoes[$y].digito_verificador+"`n"
    }
    
   
    out-file -filepath C:\Users\rferrene\Documents\Transacoes_$idCliente.csv -inputobject $csvTransacao -Encoding utf8

    out-file -filepath C:\Users\rferrene\Documents\Liquidacoes_$idCliente.csv -inputobject $csvLiquidacao -Encoding utf8

    out-file -filepath C:\Users\rferrene\Documents\Cancelados_$idCliente.csv -inputobject $csvCancelador -Encoding utf8  

}
