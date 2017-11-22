-- title:  Alura-RPG
-- author: Jeferson Silva
-- desc:   A mini RPG for TIC-80
-- script: lua

Constantes = {
  TIPO_JOGADOR = 1,
  TIPO_CHAVE = 2,
  TIPO_PORTA = 3,
  TIPO_INIMIGO = 4,
  TIPO_ESPADA = 5,

  SPRITE_JOGADOR =  256,
  SPRITE_CHAVE = 288,
  SPRITE_PORTA = 290,
  SPRITE_INIMIGO = 384,
  SPRITE_CORACAO_VAZIO = 352,
  SPRITE_CORACAO_CHEIO = 368,
  SPRITE_CHAVE_PEQUENA = 354,

  BLOCOID_CHAVE = 224,
  BLOCOID_PORTA = 225,
  BLOCOID_INIMIGO = 226,
  BLOCOID_SAIDA = 32,

  VELOCIDADE_ANIMACAO_JOGADOR = 0.2,
  VELOCIDADE_ANIMACAO_INIMIGO = 0.2,

  ID_SOM_CHAVE = 0,
  ID_SOM_INIMIGO_ATINGIDO = 1,
  ID_SOM_PORTA = 2,
  ID_SOM_ESPADA = 3,
  ID_SOM_JOGADOR_ATINGIDO = 4,
  ID_SOM_INICIO = 5,
  ID_SOM_FINAL = 6
}

Estado = {
  PARADO = 1,
  ANDANDO = 2,
  PERSEGUINDO = 3,
  ATINGIDO = 4,
  NORMAL = 5
}

Tela = {
  TITULO = 1,
  JOGO = 2,
  FINAL = 3
}

CIMA = 1
BAIXO = 2
ESQUERDA = 3
DIREITA = 4

Direcao = {
  {deltaX = 0, deltaY = -1},
  {deltaX = 0, deltaY = 1},
  {deltaX = -1, deltaY = 0},
  {deltaX = 1, deltaY = 0}
}

AnimacaoJogador = {
  { -- andando para cima
    {sprite = 256},
    {sprite = 258}
  },
  { -- andando para baixo
    {sprite = 260},
    {sprite = 262}
  },
  { -- andando para esquerda
    {sprite = 264},
    {sprite = 266}
  },
  { -- andando para direita
    {sprite = 268},
    {sprite = 270}
  }
}

AnimacaoInimigo = {
  { -- andando pra cima
    {sprite = 384},
    {sprite = 386}
  },
  { -- andando pra baixo
    {sprite = 388},
    {sprite = 390}
  },
  { -- andando pra esquerda
    {sprite = 392},
    {sprite = 394}
  },
  { -- andando pra direita
    {sprite = 396},
    {sprite = 398}
  },
}

QuadrosAtaque = {
  { -- ataque para cima
    {x = -16, y = 0, sprite = 320},
    {x = -12, y = -12, sprite = 322},
    {x = 0, y = -16, sprite = 324},
    {x = 12, y = -12, sprite = 326},
    {x = 16, y = 0, sprite = 328}
  },
  { -- ataque para baixo
    {x = 16, y = 0, sprite = 328},
    {x = 12, y = 12, sprite = 330},
    {x = 0, y = 16, sprite = 332},
    {x = -12, y = 12, sprite = 334},
    {x = -16, y = 0, sprite = 320}
  },
  { -- ataque para esquerda
    {x = 0, y = 16, sprite = 332},
    {x = -12, y = 12, sprite = 334},
    {x = -16, y = 0, sprite = 320},
    {x = -12, y = -12, sprite = 322},
    {x = 0, y = -16, sprite = 324}
  },
  { -- ataque para direita
    {x = 0, y = -16, sprite = 324},
    {x = 12, y = -12, sprite = 326},
    {x = 16, y = 0, sprite = 328},
    {x = 12, y = 12, sprite = 330},
    {x = 0, y = 16, sprite = 332}
  }
}

objetos = {}
objetosIniciais = {}
jogador = {}
espada = {}
camera = {}
posicaoDaSaida = {}

quadroDoJogo = 0
telaDoJogo = Tela.TITULO
proximaTela = nil
tempoAteTransicao = 0

function inicializa()
  leObjetosDoMapa()
end

function leObjetosDoMapa()
  for linha = 0, 34 do
    for coluna = 0, 60 do
      local blocoId = mget(coluna, linha)
      if blocoId == Constantes.BLOCOID_SAIDA then
        posicaoDaSaida = {
          x = coluna * 8 + 8,
          y = linha * 8 + 8
        }
      elseif blocoId == Constantes.BLOCOID_CHAVE or
       blocoId == Constantes.BLOCOID_PORTA or
       blocoId == Constantes.BLOCOID_INIMIGO then
        mset(coluna, linha, 0)
        local objeto = {
          blocoId = blocoId,
          coluna = coluna,
          linha = linha
        }
        table.insert(objetosIniciais, objeto)
      end
    end
  end
end

function resetaJogo()
  jogador = {
    sprite = Constantes.SPRITE_JOGADOR,
    x = 120,
    y = 68,
    corTransparente = 6,
    tipo = Constantes.TIPO_JOGADOR,
    chaves = 0,
    direcao = BAIXO,
    quadroDeAnimacao = 1,
    vida = 5,
    vidaMaxima = 5,
    estado = Estado.NORMAL,
    tempoInvulneravel = 0,
  }
  espada = {
    visivel = false,
    x = -16,
    y = -16,
    sprite = 0,
    tipo = Constantes.TIPO_ESPADA
  }
  camera = {
    x = 0,
    y = 0
  }
  criaObjetosIniciais()
end

function criaObjetosIniciais()
  objetos = {}
  for indice, objetoACriar in pairs(objetosIniciais) do
    local objeto = nil
    if objetoACriar.blocoId == Constantes.BLOCOID_CHAVE then
      objeto = criaChave(objetoACriar.coluna, objetoACriar.linha)
    elseif objetoACriar.blocoId == Constantes.BLOCOID_PORTA then
      objeto = criaPorta(objetoACriar.coluna, objetoACriar.linha)
    elseif objetoACriar.blocoId == Constantes.BLOCOID_INIMIGO then
      objeto = criaInimigo(objetoACriar.coluna, objetoACriar.linha)
    end
    table.insert(objetos, objeto)
  end
end

function criaChave(coluna, linha)
  local chave = {
    sprite = Constantes.SPRITE_CHAVE,
    corTransparente = 6,
    x = (coluna * 8) + 8,
    y = (linha * 8) + 8,
    tipo = Constantes.TIPO_CHAVE
  }
  return chave
end

function criaPorta(coluna, linha)
  local porta = {
    sprite = Constantes.SPRITE_PORTA,
    corTransparente = 6,
    x = (coluna * 8) + 8,
    y = (linha * 8) + 8,
    tipo = Constantes.TIPO_PORTA
  }
  return porta
end

function criaInimigo(coluna, linha)
  local inimigo = {
    sprite = Constantes.SPRITE_INIMIGO,
    corTransparente = 14,
    x = (coluna * 8) + 8,
    y = (linha * 8) + 8,
    tipo = Constantes.TIPO_INIMIGO,
    estado = Estado.PARADO,
    tempoDeEspera = 15,
    vida = 3,
    quadroDeAnimacao = 1,
    direcao = BAIXO
  }
  return inimigo
end

function TIC()
  atualiza()
  desenha()
end

function atualiza()
  quadroDoJogo = quadroDoJogo + 1

  if telaDoJogo == Tela.TITULO then
    atualizaTelaDeTitulo()
  elseif telaDoJogo == Tela.JOGO then
    atualizaJogo()
  elseif telaDoJogo == Tela.FINAL then
    atualizaTelaFinal()
  end

  if proximaTela ~= nil then
    if tempoAteTransicao > 0 then
      tempoAteTransicao = tempoAteTransicao - 1
    else
      telaDoJogo = proximaTela
      proximaTela = nil
    end
  end
end

function atualizaTelaDeTitulo()
  if proximaTela == nil then
    if btn(4) then
      sfx(
        Constantes.ID_SOM_INICIO,
        72, -- número da nota (12 notas por oitava)
        32, -- duracao em quadros
        0,  -- canal
        8,  -- volume
        0   -- velocidade
      )

      resetaJogo()
      proximaTela = Tela.JOGO
      tempoAteTransicao = 90
    end
  end
end

function atualizaJogo()
  if proximaTela == nil then
    atualizaJogador()
  end
  for indice, objeto in pairs(objetos) do
    atualizaObjeto(objeto)
  end
end

function atualizaTelaFinal()
  if proximaTela == nil then
    if btn(4) then
      proximaTela = Tela.TITULO
      tempoAteTransicao = 15
    end
  end
end

function atualizaJogador()
  if jogador.tempoInvulneravel > 0 then
    jogador.tempoInvulneravel = jogador.tempoInvulneravel - 1
  end

  if jogador.x == posicaoDaSaida.x and jogador.y == posicaoDaSaida.y then
    sfx(
      Constantes.ID_SOM_FINAL,
      36, -- número da nota (12 notas por oitava)
      32, -- duracao em quadros
      0,  -- canal
      8,  -- volume
      0   -- velocidade
    )

    proximaTela = Tela.FINAL
    tempoAteTransicao = 60
  end

  temColisao(jogador, 0, 0) -- para verificar se tem colisao com algum inimigo

  -- cima
  if btn(0) then
    jogador.direcao = CIMA
    if not temColisao(jogador, Direcao[CIMA].deltaX, Direcao[CIMA].deltaY) then
      jogador.y = jogador.y - 1
      camera.y = camera.y - 1
      jogador.quadroDeAnimacao = jogador.quadroDeAnimacao + Constantes.VELOCIDADE_ANIMACAO_JOGADOR
    end
  end

  -- baixo
  if btn(1) then
    jogador.direcao = BAIXO
    if not temColisao(jogador, Direcao[BAIXO].deltaX, Direcao[BAIXO].deltaY) then
      jogador.y = jogador.y + 1
      camera.y = camera.y + 1
      jogador.quadroDeAnimacao = jogador.quadroDeAnimacao + Constantes.VELOCIDADE_ANIMACAO_JOGADOR
    end
  end

  -- esquerda
  if btn(2) then
    jogador.direcao = ESQUERDA
    if not temColisao(jogador, Direcao[ESQUERDA].deltaX, Direcao[ESQUERDA].deltaY) then
      jogador.x = jogador.x - 1
      camera.x = camera.x - 1
      jogador.quadroDeAnimacao = jogador.quadroDeAnimacao + Constantes.VELOCIDADE_ANIMACAO_JOGADOR
    end
  end

  -- direita
  if btn(3) then
    jogador.direcao = DIREITA
    if not temColisao(jogador, Direcao[DIREITA].deltaX, Direcao[DIREITA].deltaY) then
      jogador.x = jogador.x + 1
      camera.x = camera.x + 1
      jogador.quadroDeAnimacao = jogador.quadroDeAnimacao + Constantes.VELOCIDADE_ANIMACAO_JOGADOR
    end
  end

  if jogador.quadroDeAnimacao >= 3 then
    jogador.quadroDeAnimacao = jogador.quadroDeAnimacao - 2
  end

  -- ataque
  if btn(4) then
    if not espada.visivel then
      sfx(
        Constantes.ID_SOM_ESPADA,
        86, -- número da nota (12 notas por oitava)
        15, -- duracao em quadros
        0,  -- canal
        8,  -- volume
        2   -- velocidade
      )

      espada.quadrosDeAtaque = QuadrosAtaque[jogador.direcao]
      espada.quadro = 1
      espada.visivel = true
    end
  end

  if espada.visivel then
    espada.quadro = espada.quadro + 0.45
    if espada.quadro < 6 then
      local quadro = math.floor(espada.quadro)
      espada.x = jogador.x + espada.quadrosDeAtaque[quadro].x
      espada.y = jogador.y + espada.quadrosDeAtaque[quadro].y
      espada.sprite = espada.quadrosDeAtaque[quadro].sprite

      temColisaoComObjeto(espada, 0, 0)
    else
      espada.visivel = false
    end
  end
end

function atualizaObjeto(objeto)
  if objeto.tipo == Constantes.TIPO_INIMIGO then
    atualizaInimigo(objeto)
  end
end

function atualizaInimigo(inimigo)
  local distanciaParaOJogador = calculaDistancia(jogador, inimigo)
  if distanciaParaOJogador > 12 and distanciaParaOJogador < 48 then
    if inimigo.estado == Estado.PARADO or inimigo.estado == Estado.ANDANDO then
      inimigo.estado = Estado.PERSEGUINDO
    end
  elseif (inimigo.estado == Estado.PERSEGUINDO) then
    inimigo.estado = Estado.PARADO
    inimigo.tempoDeEspera = 15
  end

  if (inimigo.estado == Estado.PARADO) then
    atualizaEstadoParado(inimigo)
  elseif (inimigo.estado == Estado.ANDANDO) then
    atualizaEstadoAndando(inimigo)
  elseif (inimigo.estado == Estado.PERSEGUINDO) then
    atualizaEstadoPerseguindo(inimigo)
  elseif (inimigo.estado == Estado.ATINGIDO) then
    atualizaEstadoAtingido(inimigo)
  end
end

function atualizaEstadoParado(inimigo)
  if inimigo.tempoDeEspera > 0 then
    inimigo.tempoDeEspera = inimigo.tempoDeEspera - 1
  else
    local indiceDirecao = math.random(1, 4)
    inimigo.direcao = indiceDirecao
    inimigo.distancia = math.random(16, 64)
    inimigo.estado = Estado.ANDANDO
  end
end

function atualizaEstadoAndando(inimigo)
  if inimigo.distancia > 0 then
    inimigo.distancia = inimigo.distancia - 1
    if temColisao(inimigo, Direcao[inimigo.direcao].deltaX, Direcao[inimigo.direcao].deltaY) then
      inimigo.distancia = 0
    else
      inimigo.x = inimigo.x + Direcao[inimigo.direcao].deltaX * 0.5
      inimigo.y = inimigo.y + Direcao[inimigo.direcao].deltaY * 0.5
      atualizaAnimacaoInimigo(inimigo)
    end
  else
    inimigo.tempoDeEspera = math.random(30) + 15
    inimigo.estado = Estado.PARADO
  end
end

function atualizaEstadoPerseguindo(inimigo)
  local deltaX = jogador.x - inimigo.x
  local deltaY = jogador.y - inimigo.y

  -- normalizando os deltas para facilitar escolher a velocidade
  if math.abs(deltaX) > 0.0 then
    deltaX = deltaX / math.abs(deltaX)
  end
  if math.abs(deltaY) > 0.0 then
    deltaY = deltaY / math.abs(deltaY)
  end

  if not temColisao(inimigo, deltaX, 0) then
    inimigo.x = inimigo.x + deltaX * 0.5
    if (deltaX < 0.0) then
      inimigo.direcao = ESQUERDA
    else
      inimigo.direcao = DIREITA
    end
  end
  if not temColisao(inimigo, 0, deltaY) then
    inimigo.y = inimigo.y + deltaY * 0.5
    if (deltaY < 0.0) then
      inimigo.direcao = CIMA
    else
      inimigo.direcao = BAIXO
    end
  end
  atualizaAnimacaoInimigo(inimigo)
end

function atualizaAnimacaoInimigo(inimigo)
  inimigo.quadroDeAnimacao = inimigo.quadroDeAnimacao + Constantes.VELOCIDADE_ANIMACAO_INIMIGO
  if inimigo.quadroDeAnimacao >= 3 then
    inimigo.quadroDeAnimacao = inimigo.quadroDeAnimacao - 2
  end
end

function atualizaEstadoAtingido(inimigo)
  if not temColisao(inimigo, inimigo.direcaoEmpurrao.deltaX, 0) then
    inimigo.x = inimigo.x + inimigo.direcaoEmpurrao.deltaX
  end
  if not temColisao(inimigo, 0, inimigo.direcaoEmpurrao.deltaY) then
    inimigo.y = inimigo.y + inimigo.direcaoEmpurrao.deltaY
  end

  inimigo.distancia = inimigo.distancia - 1
  if (inimigo.distancia <= 0) then
    inimigo.estado = Estado.PARADO
    inimigo.tempoDeEspera = 15
  end
end

function calculaDistancia(objetoA, objetoB)
  local deltaX = objetoA.x - objetoB.x
  local deltaY = objetoA.y - objetoB.y

  return math.sqrt(deltaX * deltaX + deltaY * deltaY)
end

function desenha()
  cls()

  if telaDoJogo == Tela.TITULO then
    desenhaTelaDeTitulo()
  elseif telaDoJogo == Tela.JOGO then
    desenhaTelaDeJogo()
  elseif telaDoJogo == Tela.FINAL then
    desenhaTelaFinal()
  end
end

function desenhaTelaDeTitulo()
  local desenhaChamada = true
  if proximaTela ~= nil and quadroDoJogo % 8 >= 4 then
    desenhaChamada = false
  end

  if desenhaChamada then
    desenhaTexto("Pressione Z para iniciar",56, 108, 15)
  end
end

function desenhaTelaDeJogo()
  desenhaMapa()
  for indice, objeto in pairs(objetos) do
    desenhaObjeto(objeto)
  end
  desenhaJogador()
  desenhaInterfaceDoUsuario()
end

function desenhaTelaFinal()
  desenhaTexto("Voce conseguiu escapar!", 56, 40, 15)
  desenhaTexto("Pressione Z para reiniciar", 48, 86, 15 )
end

function desenhaJogador()
  if jogador.vida <= 0 then
    return
  end

  local desenhaJogador = true
  if jogador.tempoInvulneravel > 0 and quadroDoJogo % 8 >= 4 then
    desenhaJogador = false
  end
  if desenhaJogador then
    local quadroDeAnimacao = math.floor(jogador.quadroDeAnimacao)
    jogador.sprite = AnimacaoJogador[jogador.direcao][quadroDeAnimacao].sprite
    desenhaObjeto(jogador)
  end
  if espada.visivel then
    desenhaObjeto(espada)
  end
end

function desenhaInterfaceDoUsuario()
  desenhaTexto("Vida", 4, 4, 15)
  desenhaVida(24, 3)
  desenhaTexto("Chaves", 148, 4, 15)
  desenhaChaves(180, 3)
end

function desenhaVida(x, y)
  for coracao=1, jogador.vidaMaxima do
    local sprite = Constantes.SPRITE_CORACAO_VAZIO
    if coracao <= jogador.vida then
      sprite = Constantes.SPRITE_CORACAO_CHEIO
    end
    spr(
      sprite,
      x + coracao * 10,
      y,
      1,  -- cor transparente
      1,  -- escala
      0,  -- sem espelhar
      0,  -- sem rotacionar
      2,  -- largura em blocos
      1   -- altura em blocos
    )
  end
end

function desenhaChaves(x, y)
  for chave=1, jogador.chaves do
    spr(
      Constantes.SPRITE_CHAVE_PEQUENA,
      x + chave * 10,
      y,
      1,  -- cor transparente
      1,  -- escala
      0,  -- sem espelhar
      0,  -- sem rotacionar
      2,  -- largura em blocos
      1   -- altura em blocos
    )
  end
end

function desenhaTexto(texto, x, y, cor)
  print(texto, x - 1, y, 0)
  print(texto, x + 1, y, 0)
  print(texto, x, y - 1, 0)
  print(texto, x, y + 1, 0)
  print(texto, x, y, cor)
end

function desenhaMapa()
  map(
    0,  -- coordenada x do bloco inicial
    0,  -- coordenada y do bloco inicial
    60, -- largura do mapa em blocos
    34, -- altura do mapa em blocos
    -camera.x,
    -camera.y
  )
end

function desenhaObjeto(objeto)
  if objeto.tipo == Constantes.TIPO_INIMIGO then
    local quadroDeAnimacao = math.floor(objeto.quadroDeAnimacao)
    objeto.sprite = AnimacaoInimigo[objeto.direcao][quadroDeAnimacao].sprite
  end

  spr(
    objeto.sprite,
    objeto.x - 8 - camera.x,
    objeto.y - 8 - camera.y,
    objeto.corTransparente,
    1, -- escala 1
    0, -- sem espelhar
    0, -- sem rotacionar
    2, -- largura em blocos 2
    2  -- altura em blocos 2
  )
end

function temColisao(objeto, deltaX, deltaY)
  if (temColisaoComObjeto(objeto, deltaX, deltaY)) then
    return true
  end

  local cantosDoObjeto = {
    superiorEsquerdo = {
      x = objeto.x - 8 + deltaX,
      y = objeto.y - 8 + deltaY
    },
    superiorDireito = {
      x = objeto.x + 7 + deltaX,
      y = objeto.y - 8 + deltaY
    },
    inferiorEsquerdo = {
      x = objeto.x - 8 + deltaX,
      y = objeto.y + 7 + deltaY
    },
    inferiorDireito = {
      x = objeto.x + 7 + deltaX,
      y = objeto.y + 7 + deltaY
    }
  }

  if (temColisaoComMapa(cantosDoObjeto.superiorEsquerdo) or
    temColisaoComMapa(cantosDoObjeto.superiorDireito) or
    temColisaoComMapa(cantosDoObjeto.inferiorEsquerdo) or
    temColisaoComMapa(cantosDoObjeto.inferiorDireito)) then
    return true
  end

  return false
end

function temColisaoComObjeto(objeto, deltaX, deltaY)
  local objetoComDelta = {
    x = objeto.x + deltaX,
    y = objeto.y + deltaY
  }
  for indice, objetoAlvo in pairs(objetos) do
    if colide(objetoComDelta, objetoAlvo) then
      if objeto.tipo == Constantes.TIPO_ESPADA and objetoAlvo.tipo == Constantes.TIPO_INIMIGO then
        fazColisaoEspadaComInimigo(objeto, objetoAlvo, indice)
      elseif objeto.tipo == Constantes.TIPO_JOGADOR then
        if objetoAlvo.tipo == Constantes.TIPO_CHAVE then
          fazColisaoJogadorComChave(indice)
        elseif objetoAlvo.tipo == Constantes.TIPO_PORTA then
          fazColisaoJogadorComPorta(indice)
          return true
        elseif objetoAlvo.tipo == Constantes.TIPO_INIMIGO then
          fazColisaoJogadorComInimigo()
        end
      elseif objeto.tipo == Constantes.TIPO_INIMIGO then
        if objetoAlvo.tipo == Constantes.TIPO_PORTA then
          return true
        end
      end
    end
  end
  return false
end

function fazColisaoEspadaComInimigo(espada, inimigo, indiceDoInimigo)
  if inimigo.estado ~= Estado.ATINGIDO then
    sfx(
      Constantes.ID_SOM_INIMIGO_ATINGIDO,
      24, -- número da nota (12 notas por oitava)
      15, -- duracao em quadros
      0,  -- canal
      8,  -- volume
      0   -- velocidade
    )

    local deltaXEmpurrao = inimigo.x - espada.x
    local deltaYEmpurrao = inimigo.y - espada.y
    local intensidade = deltaXEmpurrao * deltaXEmpurrao + deltaYEmpurrao * deltaYEmpurrao

    deltaXEmpurrao = (deltaXEmpurrao / intensidade) * 32
    deltaYEmpurrao = (deltaYEmpurrao / intensidade) * 32

    inimigo.direcaoEmpurrao = {deltaX = deltaXEmpurrao, deltaY = deltaYEmpurrao}
    inimigo.estado = Estado.ATINGIDO
    inimigo.distancia = 16
    inimigo.vida = inimigo.vida - 1
    if (inimigo.vida <= 0) then
      table.remove(objetos, indiceDoInimigo)
    end
  end
end

function fazColisaoJogadorComChave(indiceDaChave)
  sfx(
    Constantes.ID_SOM_CHAVE,
    60, -- número da nota (12 notas por oitava)
    32, -- duracao em quadros
    0,  -- canal
    8,  -- volume
    1   -- velocidade
  )
  table.remove(objetos, indiceDaChave)
  jogador.chaves = jogador.chaves + 1
end

function fazColisaoJogadorComPorta(indiceDaPorta)
  if jogador.chaves > 0 then
    sfx(
      Constantes.ID_SOM_PORTA,
      36, -- número da nota (12 notas por oitava)
      32, -- duracao em quadros
      0,  -- canal
      15, -- volume
      1   -- velocidade
    )

    table.remove(objetos, indiceDaPorta)
    jogador.chaves = jogador.chaves - 1
  else
    return true
  end
end

function fazColisaoJogadorComInimigo()
  if jogador.tempoInvulneravel == 0 then
    sfx(
      Constantes.ID_SOM_JOGADOR_ATINGIDO,
      48, -- número da nota (12 notas por oitava)
      15, -- duracao em quadros
      0,  -- canal
      8,  -- volume
      2   -- velocidade
    )

    jogador.tempoInvulneravel = 60
    jogador.vida = jogador.vida - 1
    if jogador.vida <= 0 then
      proximaTela = Tela.TITULO
      tempoAteTransicao = 120
    end
  end
end

function temColisaoComMapa(ponto)
  local blocoX = ponto.x / 8
  local blocoY = ponto.y / 8
  local blocoId = mget(blocoX, blocoY)
  if blocoEhParede(blocoId) then
    return true
  end
  return false
end

function blocoEhParede(blocoId)
  if blocoId >= 128 then
    return true
  end
  return false
end

function colide(objetoA, objetoB)
  local esquerdaDeA = objetoA.x - 8
  local direitaDeA = objetoA.x + 7
  local cimaDeA = objetoA.y - 8
  local baixoDeA = objetoA.y + 7

  local esquerdaDeB = objetoB.x - 8
  local direitaDeB = objetoB.x + 7
  local cimaDeB = objetoB.y - 8
  local baixoDeB = objetoB.y + 7

  if esquerdaDeA <= direitaDeB and
    direitaDeA >= esquerdaDeB and
    cimaDeA <= baixoDeB and
    baixoDeA >= cimaDeB then
    return true
  end
  return false
end

inicializa()