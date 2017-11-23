-- title:  Alura-RPG
-- author: Jeferson Silva
-- desc:   A mini RPG for TIC-80
-- script: lua

Constantes = {
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
camera = {}
posicaoDaSaida = {}

quadroDoJogo = 0
telaAtual = nil
proximaTela = nil
tempoAteTransicao = 0

-- Classe Objeto
-- ********************************************************
Objeto = {
  larguraSprite = 2,
  alturaSprite = 2,
  podeRemover = false
}

function Objeto:novo(objeto)
  if objeto == nil then
    objeto = {}
  end

  setmetatable(objeto, self)
  self.__index = self

  return objeto
end

function Objeto:atualiza()
end

function Objeto:desenha()
  spr(
    self.sprite,
    self.x - 8 - camera.x,
    self.y - 8 - camera.y,
    self.corTransparente,
    1,  -- escala
    0,  -- sem espelhar
    0,  -- sem rotacionar
    self.larguraSprite, -- largura em blocos
    self.alturaSprite   -- altura em blocos
  )
end

function Objeto:colideCom(objeto)
  local esquerdaDeA = self.x - 8
  local direitaDeA = self.x + 7
  local cimaDeA = self.y - 8
  local baixoDeA = self.y + 7

  local esquerdaDeB = objeto.x - 8
  local direitaDeB = objeto.x + 7
  local cimaDeB = objeto.y - 8
  local baixoDeB = objeto.y + 7

  if esquerdaDeA <= direitaDeB and
    direitaDeA >= esquerdaDeB and
    cimaDeA <= baixoDeB and
    baixoDeA >= cimaDeB then
    return true
  end
  return false
end

function Objeto:temColisao(deltaX, deltaY)
  if self:temColisaoComObjetos(deltaX, deltaY) then
    return true
  end

  local cantosDoObjeto = {
    superiorEsquerdo = {
      x = self.x - 8 + deltaX,
      y = self.y - 8 + deltaY
    },
    superiorDireito = {
      x = self.x + 7 + deltaX,
      y = self.y - 8 + deltaY
    },
    inferiorEsquerdo = {
      x = self.x - 8 + deltaX,
      y = self.y + 7 + deltaY
    },
    inferiorDireito = {
      x = self.x + 7 + deltaX,
      y = self.y + 7 + deltaY
    }
  }

  if self:temColisaoComMapa(cantosDoObjeto.superiorEsquerdo) or
    self:temColisaoComMapa(cantosDoObjeto.superiorDireito) or
    self:temColisaoComMapa(cantosDoObjeto.inferiorEsquerdo) or
    self:temColisaoComMapa(cantosDoObjeto.inferiorDireito) then
    return true
  end

  return false
end

function Objeto:temColisaoComObjetos(deltaX, deltaY)
  return false
end

function Objeto:temColisaoComMapa(ponto)
  local blocoX = ponto.x / 8
  local blocoY = ponto.y / 8
  local blocoId = mget(blocoX, blocoY)
  if blocoEhParede(blocoId) then
    return true
  end
  return false
end

function Objeto:colidiuComJogador(jogador)
  return false
end

function Objeto:colidiuComEspada(espada)
  return false
end

function Objeto:colidiuComInimigo(inimigo)
  return false
end

-- Classe Chave
-- ********************************************************
Chave = Objeto:novo({
  sprite = Constantes.SPRITE_CHAVE,
  corTransparente = 6
})

function Chave:colidiuComJogador(jogador)
  if not self.podeRemover then
    jogador:recebeChave()
    self.podeRemover = true
  end
  return false
end

-- Classe Porta
-- ********************************************************
Porta = Objeto:novo({
  sprite = Constantes.SPRITE_PORTA,
  corTransparente = 6
})

function Porta:colidiuComJogador(jogador)
  if jogador:temChave() then
    sfx(
      Constantes.ID_SOM_PORTA,
      36, -- número da nota (12 notas por oitava)
      32, -- duracao em quadros
      0,  -- canal
      15, -- volume
      1   -- velocidade
    )

    jogador:removeChave()
    self.podeRemover = true
    return false
  end
  return true
end

function Porta:colidiuComInimigo(inimigo)
  return true
end

-- Classe Jogador
-- ********************************************************
Jogador = Objeto:novo()

function Jogador:desenha()
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
    Objeto.desenha(self)
  end

  if self.espada.visivel then
    self.espada:desenha()
  end
end

function Jogador:atualiza()
  if self.tempoInvulneravel > 0 then
    self.tempoInvulneravel = self.tempoInvulneravel - 1
  end

  self:temColisao(0, 0) -- para verificar se tem colisao com algum inimigo

  -- cima
  if btn(0) then
    self:movePara(CIMA)
  end

  -- baixo
  if btn(1) then
    self:movePara(BAIXO)
  end

  -- esquerda
  if btn(2) then
    self:movePara(ESQUERDA)
  end

  -- direita
  if btn(3) then
    self:movePara(DIREITA)
  end

  -- ataque
  if btn(4) then
    self.espada:ataca()
  end

  self:atualizaAnimacao()

  self.espada:atualiza(jogador)
end

function Jogador:atualizaAnimacao()
  if self.quadroDeAnimacao >= 3 then
    self.quadroDeAnimacao = self.quadroDeAnimacao - 2
  end
end

function Jogador:movePara(indiceDirecao)
  self.direcao = indiceDirecao
  local deltaX = Direcao[indiceDirecao].deltaX
  local deltaY = Direcao[indiceDirecao].deltaY
  if not self:temColisao(deltaX, deltaY) then
    self.x = self.x + deltaX
    self.y = self.y + deltaY
    camera.x = camera.x + deltaX
    camera.y = camera.y + deltaY
    self.quadroDeAnimacao = self.quadroDeAnimacao + Constantes.VELOCIDADE_ANIMACAO_JOGADOR
  end
end

function Jogador:temColisaoComObjetos(deltaX, deltaY)
  local objetoComDelta = Objeto:novo({
    x = self.x + deltaX,
    y = self.y + deltaY
  })

  for indice, objetoAlvo in pairs(objetos) do
    if objetoComDelta:colideCom(objetoAlvo) then
      return objetoAlvo:colidiuComJogador(self)
    end
  end

  return false
end

function Jogador:recebeDano()
  if self.tempoInvulneravel == 0 then
    sfx(
      Constantes.ID_SOM_JOGADOR_ATINGIDO,
      48, -- número da nota (12 notas por oitava)
      15, -- duracao em quadros
      0,  -- canal
      8,  -- volume
      2   -- velocidade
    )

    self.tempoInvulneravel = 60
    self.vida = self.vida - 1
    if self.vida <= 0 then
      proximaTela = TelaDeTitulo:novo()
      tempoAteTransicao = 120
    end
  end
end

function Jogador:recebeChave()
  sfx(
    Constantes.ID_SOM_CHAVE,
    60, -- número da nota (12 notas por oitava)
    32, -- duracao em quadros
    0,  -- canal
    8,  -- volume
    1   -- velocidade
  )
  self.chaves = self.chaves + 1
end

function Jogador:temChave()
  return self.chaves > 0
end

function Jogador:removeChave()
  self.chaves = self.chaves - 1
end

function Jogador:chegouNaSaida()
  if self.x == posicaoDaSaida.x and self.y == posicaoDaSaida.y then
    return true
  end
  return false
end

-- Classe Espada
-- ********************************************************
Espada = Objeto:novo({})

function Espada:ataca()
  if not self.visivel then
    sfx(
      Constantes.ID_SOM_ESPADA,
      86, -- número da nota (12 notas por oitava)
      15, -- duracao em quadros
      0,  -- canal
      8,  -- volume
      2   -- velocidade
    )

    self.quadrosDeAtaque = QuadrosAtaque[jogador.direcao]
    self.quadro = 1
    self.visivel = true
  end
end

function Espada:atualiza(jogador)
  if self.visivel then
    self.quadro = self.quadro + 0.45
    if self.quadro < 6 then
      local quadro = math.floor(self.quadro)
      self.x = jogador.x + self.quadrosDeAtaque[quadro].x
      self.y = jogador.y + self.quadrosDeAtaque[quadro].y
      self.sprite = self.quadrosDeAtaque[quadro].sprite

      self:temColisaoComObjetos(0, 0)
    else
      self.visivel = false
    end
  end
end

function Espada:temColisaoComObjetos(deltaX, deltaY)
  local objetoComDelta = Objeto:novo({
    x = self.x + deltaX,
    y = self.y + deltaY
  })

  for indice, objetoAlvo in pairs(objetos) do
    if objetoComDelta:colideCom(objetoAlvo) then
      return objetoAlvo:colidiuComEspada(self)
    end
  end

  return false
end

-- Classe Estado
-- ********************************************************
Estado = {}

function Estado:novo(estado)
  if estado == nil then
    estado = {}
  end

  setmetatable(estado, self)
  self.__index = self

  return estado
end

function Estado:colidiuComEspada(inimigo, espada)
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

  inimigo.estado = EstadoAtingido:novo({
    direcaoEmpurrao = {deltaX = deltaXEmpurrao, deltaY = deltaYEmpurrao},
    distancia = 16
  })
  inimigo:recebeDano()
end

-- Classe EstadoParado
-- ********************************************************
EstadoParado = Estado:novo()

function EstadoParado:atualiza(inimigo)
  local distanciaParaOJogador = calculaDistancia(jogador, inimigo)
  if distanciaParaOJogador > 12 and distanciaParaOJogador < 48 then
    inimigo.estado = EstadoPerseguindo:novo()
    return
  end

  if self.tempoDeEspera > 0 then
    self.tempoDeEspera = self.tempoDeEspera - 1
  else
    local indiceDirecao = math.random(1, 4)
    inimigo.direcao = indiceDirecao
    inimigo.estado = EstadoAndando:novo({
      distancia = math.random(16, 64)
    })
  end
end

-- Classe EstadoAndando
-- ********************************************************
EstadoAndando = Estado:novo()

function EstadoAndando:atualiza(inimigo)
  local distanciaParaOJogador = calculaDistancia(jogador, inimigo)
  if distanciaParaOJogador > 12 and distanciaParaOJogador < 48 then
    inimigo.estado = EstadoPerseguindo:novo()
    return
  end

  if self.distancia > 0 then
    self.distancia = self.distancia - 1
    if inimigo:temColisao(
      Direcao[inimigo.direcao].deltaX,
      Direcao[inimigo.direcao].deltaY) then
      self.distancia = 0
    else
      inimigo.x = inimigo.x + Direcao[inimigo.direcao].deltaX * 0.5
      inimigo.y = inimigo.y + Direcao[inimigo.direcao].deltaY * 0.5
      inimigo:atualizaAnimacao()
    end
  else
    inimigo.estado = EstadoParado:novo({
      tempoDeEspera = math.random(30) + 15
    })
  end
end

-- Classe EstadoPerseguindo
-- ********************************************************
EstadoPerseguindo = Estado:novo()

function EstadoPerseguindo:atualiza(inimigo)
  local distanciaParaOJogador = calculaDistancia(jogador, inimigo)
  if distanciaParaOJogador <= 12 or distanciaParaOJogador >= 48 then
    inimigo.estado = EstadoParado:novo({
      tempoDeEspera = 15
    })
    return
  end

  local deltaX = jogador.x - inimigo.x
  local deltaY = jogador.y - inimigo.y

  -- normalizando os deltas para facilitar escolher a velocidade
  if math.abs(deltaX) > 0.0 then
    deltaX = deltaX / math.abs(deltaX)
  end
  if math.abs(deltaY) > 0.0 then
    deltaY = deltaY / math.abs(deltaY)
  end

  if not inimigo:temColisao(deltaX, 0) then
    inimigo.x = inimigo.x + deltaX * 0.5
    if (deltaX < 0.0) then
      inimigo.direcao = ESQUERDA
    else
      inimigo.direcao = DIREITA
    end
  end
  if not inimigo:temColisao(0, deltaY) then
    inimigo.y = inimigo.y + deltaY * 0.5
    if (deltaY < 0.0) then
      inimigo.direcao = CIMA
    else
      inimigo.direcao = BAIXO
    end
  end
  inimigo:atualizaAnimacao()
end

-- Classe EstadoAtingido
-- ********************************************************
EstadoAtingido = Estado:novo()

function EstadoAtingido:atualiza(inimigo)
  if not inimigo:temColisao(self.direcaoEmpurrao.deltaX, 0) then
    inimigo.x = inimigo.x + self.direcaoEmpurrao.deltaX
  end
  if not inimigo:temColisao(0, self.direcaoEmpurrao.deltaY) then
    inimigo.y = inimigo.y + self.direcaoEmpurrao.deltaY
  end

  self.distancia = self.distancia - 1
  if (self.distancia <= 0) then
    inimigo.estado = EstadoParado:novo({
      tempoDeEspera = 15
    })
  end
end

function EstadoAtingido:colidiuComEspada(espada)
end

-- Classe Inimigo
-- ********************************************************
Inimigo = Objeto:novo({
  sprite = Constantes.SPRITE_INIMIGO,
  corTransparente = 14,
  estado = EstadoParado:novo({
    tempoDeEspera = 15
  }),
  vida = 3,
  quadroDeAnimacao = 1,
  direcao = BAIXO
})

function Inimigo:atualiza()
  self.estado:atualiza(self)
end

function Inimigo:atualizaAnimacao()
  self.quadroDeAnimacao = self.quadroDeAnimacao + Constantes.VELOCIDADE_ANIMACAO_INIMIGO
  if self.quadroDeAnimacao >= 3 then
    self.quadroDeAnimacao = self.quadroDeAnimacao - 2
  end
end

function Inimigo:desenha()
  local quadroDeAnimacao = math.floor(self.quadroDeAnimacao)
  self.sprite = AnimacaoInimigo[self.direcao][quadroDeAnimacao].sprite

  Objeto.desenha(self)
end

function Inimigo:temColisaoComObjetos(deltaX, deltaY)
  local objetoComDelta = Objeto:novo({
    x = self.x + deltaX,
    y = self.y + deltaY
  })

  for indice, objetoAlvo in pairs(objetos) do
    if objetoComDelta:colideCom(objetoAlvo) then
      return objetoAlvo:colidiuComInimigo(self)
    end
  end

  return false
end

function Inimigo:colidiuComJogador(jogador)
  jogador:recebeDano()
  return false
end

function Inimigo:colidiuComEspada(espada)
  self.estado:colidiuComEspada(self, espada)
end

function Inimigo:recebeDano()
  self.vida = self.vida - 1
  if (self.vida <= 0) then
    self.podeRemover = true
  end
end

-- Classe Tela
-- ********************************************************
Tela = {}

function Tela:novo(tela)
  if tela == nil then
    tela = {}
  end

  setmetatable(tela, self)
  self.__index = self

  return tela
end

-- Classe TelaDeTitulo
-- ********************************************************
TelaDeTitulo = Tela:novo()

function TelaDeTitulo:atualiza()
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
      proximaTela = TelaDeJogo:novo()
      tempoAteTransicao = 90
    end
  end
end

function TelaDeTitulo:desenha()
  local desenhaChamada = true
  if proximaTela ~= nil and quadroDoJogo % 8 >= 4 then
    desenhaChamada = false
  end

  if desenhaChamada then
    desenhaTexto("Pressione Z para iniciar",56, 108, 15)
  end
end

-- Classe TelaDeJogo
-- ********************************************************
TelaDeJogo = Tela:novo()

function TelaDeJogo:atualiza()
  if proximaTela == nil then
    jogador:atualiza()

    if jogador:chegouNaSaida() then
      sfx(
        Constantes.ID_SOM_FINAL,
        36, -- número da nota (12 notas por oitava)
        32, -- duracao em quadros
        0,  -- canal
        8,  -- volume
        0   -- velocidade
      )

      proximaTela = TelaFinal:novo()
      tempoAteTransicao = 60
    end
  end
  for indice, objeto in pairs(objetos) do
    if objeto.podeRemover then
      table.remove(objetos, indice)
    else
      objeto:atualiza()
    end
  end
end

function TelaDeJogo:desenha()
  self:desenhaMapa()
  for indice, objeto in pairs(objetos) do
    objeto:desenha()
  end
  jogador:desenha()
  self:desenhaInterfaceDoUsuario()
end

function TelaDeJogo:desenhaMapa()
  map(
    0,  -- coordenada x do bloco inicial
    0,  -- coordenada y do bloco inicial
    60, -- largura do mapa em blocos
    34, -- altura do mapa em blocos
    -camera.x,
    -camera.y
  )
end

function TelaDeJogo:desenhaInterfaceDoUsuario()
  desenhaTexto("Vida", 4, 4, 15)
  self:desenhaVida(24, 3)
  desenhaTexto("Chaves", 148, 4, 15)
  self:desenhaChaves(180, 3)
end

function TelaDeJogo:desenhaVida(x, y)
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

function TelaDeJogo:desenhaChaves(x, y)
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

-- Classe TelaFinal
-- ********************************************************
TelaFinal = Tela:novo()

function TelaFinal:atualiza()
  if proximaTela == nil then
    if btn(4) then
      proximaTela = TelaDeTitulo:novo()
      tempoAteTransicao = 15
    end
  end
end

function TelaFinal:desenha()
  desenhaTexto("Voce conseguiu escapar!", 56, 40, 15)
  desenhaTexto("Pressione Z para reiniciar", 48, 86, 15 )
end

-- Funções do jogo
-- ********************************************************
function inicializa()
  telaAtual = TelaDeTitulo:novo()
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
  jogador = Jogador:novo({
    sprite = Constantes.SPRITE_JOGADOR,
    x = 120,
    y = 68,
    corTransparente = 6,
    chaves = 0,
    direcao = BAIXO,
    quadroDeAnimacao = 1,
    vida = 5,
    vidaMaxima = 5,
    tempoInvulneravel = 0,
    espada = Espada:novo({
      visivel = false,
      x = -16,
      y = -16,
      sprite = 0
    })
  })
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
    local posicao = {
      x = objetoACriar.coluna * 8 + 8,
      y = objetoACriar.linha * 8 + 8
    }
    if objetoACriar.blocoId == Constantes.BLOCOID_CHAVE then
      objeto = Chave:novo(posicao)
    elseif objetoACriar.blocoId == Constantes.BLOCOID_PORTA then
      objeto = Porta:novo(posicao)
    elseif objetoACriar.blocoId == Constantes.BLOCOID_INIMIGO then
      objeto = Inimigo:novo(posicao)
    end
    table.insert(objetos, objeto)
  end
end

function TIC()
  atualiza()
  desenha()
end

function atualiza()
  quadroDoJogo = quadroDoJogo + 1

  telaAtual:atualiza()

  if proximaTela ~= nil then
    if tempoAteTransicao > 0 then
      tempoAteTransicao = tempoAteTransicao - 1
    else
      telaAtual = proximaTela
      proximaTela = nil
    end
  end
end

function desenha()
  cls()
  telaAtual:desenha()
end

-- Funções de utilidade
-- ********************************************************
function calculaDistancia(objetoA, objetoB)
  local deltaX = objetoA.x - objetoB.x
  local deltaY = objetoA.y - objetoB.y

  return math.sqrt(deltaX * deltaX + deltaY * deltaY)
end

function blocoEhParede(blocoId)
  if blocoId >= 128 then
    return true
  end
  return false
end

function desenhaTexto(texto, x, y, cor)
  print(texto, x - 1, y, 0)
  print(texto, x + 1, y, 0)
  print(texto, x, y - 1, 0)
  print(texto, x, y + 1, 0)
  print(texto, x, y, cor)
end

inicializa()
