extensions [table py]
turtles-own [ tipo detritos memoria  tipo-de-poluicao probabilidade-depositos]
patches-own [ sujo? deposito? tempo-limpo painel-solar? painel-usado? tempo-de-vida eficiencia  tipo-de-lixo ]

globals [ cleaner polluter-tipos recarregamento? energia tempo-desde-carregamento quantidade-de-lixo solar-timer openSet closedSet cameFrom gScore fScore patches-recentes dirty-patches quantidade-de-limpo bomba-usada? bomba-temporizador]



to setup
  clear-all

  ; Variáveis ajustáveis pelo utilizador
  set  energia energia-inicial   ; Energia inicial do Cleaner, ajustada via slider
  set capacidade-detritos capacidade-detritos ; Capacidade máxima de detritos ajustável via slider
  set postos-deposito postos-deposito  ; Número de postos de depósito ajustável
  set recarregamento? false     ; Inicialmente, não está recarregando
  set tempo-desde-carregamento 0
  set solar-timer 0
  set patches-recentes []
  set dirty-patches no-patches
  set bomba-usada? false   ; A bomba ainda não foi usada
  set bomba-temporizador 0  ; O temporizador para a bomba começa em 0

  tocar-som


  ; Limpar o ambiente
  ask patches [
    set sujo? false
    set deposito? false
    set pcolor white
    set tempo-limpo 0
    set painel-solar? false


  ]

  ; Criar contentores de depósito
  create-contentores postos-deposito

  ; Criar Cleaner no canto inferior esquerdo
  create-turtles 1 [
    set tipo "cleaner"
    set energia energia-inicial
    set detritos 0
    setxy min-pxcor min-pycor  ;; Posição inicial
    set cleaner self
    set size 2
    set shape "cleaner"
    set memoria []


  ]

  ; Criar Polluters
  create-polluters

  reset-ticks
  clear-all-plots
end

to create-contentores [ n ]
  repeat n [
    let patch-alvo one-of patches with [not deposito?]
    ask patch-alvo [
      set deposito? true
      set pcolor black  ; Contentores são pretos

    ]
  ]
end
to create-random-solar-panel
  if count patches with [painel-solar?] < 5 [  ; max-paineis-solares definido como slider ou variável
    if random 100 < 5 [
      let patch-alvo one-of patches with [not painel-solar? and not sujo? and not deposito?]
      ask patch-alvo [
        set painel-solar? true
        set pcolor blue
        set tempo-de-vida random 35 + 1
        set eficiencia random 3 + 1
        set painel-usado? false  ; O painel ainda não foi utilizado
      ]
    ]
  ]
end
to verificar-paineis-solares
  ask patches with [painel-solar?] [
    set tempo-de-vida tempo-de-vida - 1  ; Diminui o tempo de vida a cada tick
    if tempo-de-vida <= 0 [
      set painel-solar? false  ; Remove o painel solar
      set pcolor white         ; Volta a cor do patch ao normal
    ]
  ]
end

to create-polluters
  ; Criar o primeiro polluter com poluição leve
  create-turtles 1 [
    set tipo "polluter"
    set size 1.8
    set shape "truck trash"
    setxy random-xcor random-ycor
    set tipo-de-poluicao "leve"
    set probabilidade-depositos prob-polluter-1
  ]

  ; Criar o segundo polluter com poluição pesada
  create-turtles 1 [
    set tipo "polluter"
    set size 1.8
    set shape "truck trash"
    setxy random-xcor random-ycor
    set tipo-de-poluicao "pesada"
    set probabilidade-depositos prob-polluter-2
  ]

  ; Criar o terceiro polluter com poluição tóxica
  create-turtles 1 [
    set tipo "polluter"
    set size 1.8
    set shape "truck trash"
    setxy random-xcor random-ycor
    set tipo-de-poluicao "toxica"
    set probabilidade-depositos prob-polluter-3
  ]
end


to go_once
  go
  stop
end

to go_n
  repeat vezes [ go ]
end



to go

  if bomba-temporizador > 0 [
    set bomba-temporizador bomba-temporizador - 1   ; Reduz o temporizador a cada tick
    print (word "Cleaner parado. Restam " bomba-temporizador " ticks.")
    stop
  ]

  ask cleaner [
    schedule-actions
  ]
  ask turtles with [ tipo = "polluter" ] [ mover-e-poluente ]
  create-random-solar-panel
  verificar-paineis-solares

  set quantidade-de-lixo count patches with [ sujo? ]
  set-current-plot "Evolução do lixo"
  set-current-plot-pen "lixo"
  plot quantidade-de-lixo

  set quantidade-de-limpo count patches with [ not sujo? ]
  set-current-plot "Evolução do lixo limpo"
  set-current-plot-pen "lixo limpo"
  plot quantidade-de-limpo
  tick
end

to schedule-actions
  ; Verifica se o Cleaner está recarregando
  if recarregamento? [
    continuar-recarregar
    stop
  ]

  ; Prioridade 1: Descarregar detritos se a capacidade estiver cheia
  if detritos >= capacidade-detritos [
    print "Capacidade de detritos cheia. Planejando descarregar..."
    let destino planejar-viagem "deposito"
    ifelse destino = nobody [
      print "Nenhum depósito disponível. Continuando a procurar patches sujos..."
      mover-e-limpar
    ][
      let caminho planejar-caminho destino
      ifelse not empty? caminho [
        seguir-caminho caminho
        ; Descarregar ao chegar no depósito
        descarregar
      ][
        print "Caminho não gerado corretamente para o depósito."
        mover-e-limpar
      ]
    ]
    stop
  ]
   ; Prioridade 2: Recarregar se a energia estiver baixa
  if energia < energia-inicial * 0.2 and not recarregamento? [
    print "Energia muito baixa. Planejando recarregar..."
    let destino planejar-viagem "painel-solar"
    ifelse destino = nobody [
      print "Nenhum painel solar disponível. Continuando a procurar patches sujos..."
      mover-e-limpar
    ][
      print "Painel solar encontrado. Planejando caminho..."
      let caminho planejar-caminho destino
      ifelse not empty? caminho [
        seguir-caminho caminho
        ; Recarregar ao chegar no painel solar
        if [painel-solar?] of patch-here and not [painel-usado?] of patch-here [
          recarregar-instantaneamente
          ask patch-here [
            set painel-usado? true
            set pcolor gray
          ]
        ]
      ][
        print "Caminho não gerado corretamente para o painel solar."
        mover-e-limpar
      ]
    ]
    stop
  ]


  ; Prioridade 3: Limpeza inteligente e eficiente
  if quantidade-de-lixo >= 5 [
    mover-e-limpar
    stop
  ]

  ; Prioridade 4: Exploração aleatória se não houver patches sujos visíveis
  andar-explorar
end

to-report a-star [start goal]
  ;; Initialize
  set openSet (list (list [pxcor] of start [pycor] of start))
  set closedSet []
  set cameFrom table:make
  set gScore table:make
  set fScore table:make

  table:put gScore (list [pxcor] of start [pycor] of start) 0
  table:put fScore (list [pxcor] of start [pycor] of start) (heuristic-cost start goal)

  while [not empty? openSet] [
    ;; Find the node in openSet with the lowest fScore
    let current-coords get-node-with-lowest-fScore openSet
    let current patch (item 0 current-coords) (item 1 current-coords)

    if current = goal [
      let path-and-energy reconstruct-path current-coords
      report path-and-energy
    ]

    set openSet remove current-coords openSet
    set closedSet lput current-coords closedSet

    ;; Get neighbor patches
    let neighbor-patches [neighbors4] of current
    let valid-neighbors neighbor-patches with [
      not member? (list pxcor pycor) closedSet
      and pxcor >= min-pxcor and pxcor <= max-pxcor
      and pycor >= min-pycor and pycor <= max-pycor
    ]
    let neighbor-list [self] of valid-neighbors

    foreach neighbor-list [neighbor ->
      let neighbor-coords (list [pxcor] of neighbor [pycor] of neighbor)
      let movement-cost 1
      let neighbor-cost (calcular-custo-de-patch neighbor)

      ;; Retrieve curr-gScore safely
      let curr-gScore 999999  ; Default to high value
      if table:has-key? gScore current-coords [
        set curr-gScore table:get gScore current-coords
      ]

      let tentative-gScore (curr-gScore + movement-cost + neighbor-cost)

      ;; Retrieve neighbor-gScore safely
      let neighbor-gScore 999999  ; Default to high value
      if table:has-key? gScore neighbor-coords [
        set neighbor-gScore table:get gScore neighbor-coords
      ]

      if (tentative-gScore < neighbor-gScore) [
        table:put cameFrom neighbor-coords current-coords
        table:put gScore neighbor-coords tentative-gScore
        table:put fScore neighbor-coords (tentative-gScore + heuristic-cost neighbor goal)

        if not member? neighbor-coords openSet [
          set openSet lput neighbor-coords openSet
        ]
      ]
    ]
  ]

  ;; No path found
  report []
end


to-report get-node-with-lowest-fScore [node-list]
  let min-node nobody
  let min-fScore 999999
  foreach node-list [node ->
    let fScore-value 999999
    if table:has-key? fScore node [
      set fScore-value table:get fScore node
    ]
    if fScore-value < min-fScore [
      set min-fScore fScore-value
      set min-node node
    ]
  ]
  report min-node
end




to-report heuristic-cost [from pa]
  ; Euclidean distance as the heuristic
  report [distance from ] of  pa
end
to-report calcular-custo-de-patch [alvo-patch]
  let custo 1  ; Custo base para movimentação

  ; Aumenta o custo se o patch estiver sujo
  if [sujo?] of alvo-patch [
    if [tipo-de-lixo] of alvo-patch = "pesada" [
      set custo custo + (energia * 0.25)  ; Aumenta o custo em 25% com base na energia
    ]
    if [tipo-de-lixo] of alvo-patch = "toxica" [
      set custo custo + (energia * 0.5)   ; Aumenta o custo em 50% com base na energia
    ]
  ]


  report custo
end

to-report reconstruct-path [current]
  let total-path (list current)
  let total-energy 0

  ; Reconstruct the path by going back through the cameFrom table
  while [ table:has-key? cameFrom current ] [
    set current table:get cameFrom current
    set total-path fput current total-path

    ; Transformar coordenadas em agente patch antes de passar para calcular-custo-de-patch
    let patch-atual patch (item 0 current) (item 1 current)  ;; Converter coordenadas em patch
    set total-energy total-energy + calcular-custo-de-patch patch-atual  ; Add energy cost for this patch
  ]

  ; Report both the path and the total energy cost
  report (list total-path total-energy)
end

to-report reconstruct-path-parcial [current]
  let total-path (list current)
  let total-energy 0

  ; Reconstruct the path by going back through the cameFrom table
  while [ table:has-key? cameFrom current ] [
    set current table:get cameFrom current
    set total-path fput current total-path

    ; Transformar coordenadas em agente patch antes de passar para calcular-custo-de-patch
    let patch-atual patch (item 0 current) (item 1 current)
    set total-energy total-energy + calcular-custo-de-patch patch-atual  ; Add energy cost for this patch
  ]

  ; Report both the path and the energy cost for this partial path
  report (list total-path total-energy)
end



to-report planejar-viagem [objetivo]
  let destino nobody

  ; Encontrar o destino com base no objetivo
  if objetivo = "painel-solar" [
    print "Procurando painel solar mais próximo..."
    set destino min-one-of patches with [painel-solar? and not painel-usado? ] [distance myself]
  ]
  if objetivo = "deposito" [
    print "Procurando depósito mais próximo..."
    set destino min-one-of patches with [deposito?] [distance myself]
  ]

  ; Verificar se há um destino válido
  if destino = nobody [
    print (word "Nenhum " objetivo " encontrado! Cancelando planejamento.")
    report nobody  ; Retorna nobody se não encontrar destino
  ]

  ; Logando o destino encontrado
  print (word "Destino encontrado: " destino ", distância: " distance destino)

  report destino  ; Retorna o destino encontrado
end


to-report planejar-caminho [destino]
  ; Gera o caminho com A*
  let caminho a-star patch-here destino

  ; Loga o processo do A* se necessário
  ifelse empty? caminho [
    print (word "Nenhum caminho viável encontrado até o destino: " destino)
  ][
    print "Caminho viável encontrado com A*."
  ]

  report caminho
end




to seguir-caminho [caminho]
  let total-path first caminho  ; Extrair o caminho
  print "Seguindo o caminho planejado..."

  foreach total-path [ etapa ->
    let x (item 0 etapa)
    let y (item 1 etapa)
    let patch-alvo patch x y  ; Converter coordenadas para patch
    print (word "Movendo para patch: " patch-alvo)

    face patch-alvo
    fd 1

    ; Verificar se o patch tem lixo e limpar


    ; Penalização de energia ao passar por patches sujos
    ifelse [sujo?] of patch-alvo [
      ifelse [tipo-de-lixo] of patch-alvo = "pesada" [
        set energia energia - (energia-inicial * 0.25)  ; Penaliza em 25% a energia inicial
        print (word "Passou por lixo pesada. Energia reduzida em 25%. Energia atual: " energia)
      ][

        ifelse [tipo-de-lixo] of patch-alvo = "toxica" [
          set energia energia - (energia-inicial * 0.5)  ; Penaliza em 50% a energia inicial
          print (word "Passou por lixo tóxica. Energia reduzida em 50%. Energia atual: " energia)
        ][
          set energia energia - 1
          print (word "Passou por lixo leve. Energia reduzida em 1. Energia atual: " energia)
        ]
      ]


    ][
          set energia energia - 1
    ]

    if [sujo?] of patch-alvo [

      ifelse detritos <= capacidade-detritos[
        set detritos detritos + 1
         print "Patch sujo encontrado! Limpando..."
        ask patch-alvo [
          set sujo? false
          set pcolor white  ; Volta à cor original
          set tempo-limpo ticks  ; Marca o tempo em que foi limpo
        ]
      ][

        print "Cleaner cheio..."
      ]



    ]

    ; Reduzir a energia a cada movimento

    print (word "Energia restante: " energia)

    ; Verificar se a energia acabou
    if energia <= 0 [
      print "Energia esgotada! Necessário recarregar."
      recarregar
      stop
    ]
  ]
  print "Chegou ao destino!"
end




to logar-detalhes-do-caminho [caminho]
  ; Se o caminho estiver vazio, não foi gerado corretamente
  ifelse empty? caminho [
    print "Nenhum caminho viável foi gerado."
  ][
    ; Caso um caminho tenha sido gerado, logamos os detalhes
    print (word "Caminho gerado: " caminho)

    ; Loga as coordenadas de cada patch no caminho
    foreach caminho [ patch-no-caminho ->
      print (word "Patch no caminho: " [pxcor] of patch-no-caminho "," [pycor] of patch-no-caminho)
    ]

    ; Estimativa de energia necessária
    let energia-necessaria estimar-energia-necessaria caminho
    print (word "Energia estimada necessária para este caminho: " energia-necessaria)
  ]

  ; Loga a energia atual e outros detalhes úteis
  print (word "Energia atual do Cleaner: " energia)
end

to-report estimar-energia-necessaria [caminho]
  let energia-total 0  ; Variável para armazenar o custo total de energia

  ; Percorre o caminho e calcula o custo de energia para cada patch
  foreach caminho [ patch-no-caminho ->
    let custo 1  ; Custo base por movimento

    ; Se o patch estiver sujo, aplica penalidades de energia
    if [sujo?] of patch-no-caminho [
      if [tipo-de-lixo] of patch-no-caminho = "pesada" [
        set custo custo + (energia-inicial * 0.25)  ; Aumenta o custo em 25% para lixo pesada
      ]
      if [tipo-de-lixo] of patch-no-caminho = "toxica" [
        set custo custo + (energia-inicial * 0.5)   ; Aumenta o custo em 50% para lixo tóxica
      ]
    ]

    ; Adiciona o custo desse patch ao total de energia necessária
    set energia-total energia-total + custo
  ]

  report energia-total  ; Retorna a energia total estimada
end


to procurar-e-recarregar
  let painel-alvo one-of patches in-radius 3 with [painel-solar?]
  if painel-alvo != nobody [
    face painel-alvo
    fd 0.8
    if [painel-solar?] of patch-here [
      recarregar-instantaneamente
    ]
  ]
end

; Comportamento do Cleaner: mover-se, limpar e descarregar
to mover-e-limpar
  if not recarregamento? [
    ; Verifica se há painéis solares no alcance
    let painel-alvo one-of patches in-radius 3 with [painel-solar? and not painel-usado?]

    ; Se houver um painel solar no alcance, vai para ele e recarrega
    if painel-alvo != nobody [
      face painel-alvo
      safe-move 0.8

      ; Verifica se chegou ao painel solar
      if [painel-solar?] of patch-here and not [painel-usado?] of patch-here [
        recarregar-instantaneamente
        ask patch-here [
          set painel-usado? true  ; Marca o painel como utilizado
          set pcolor gray         ; Muda a cor para indicar que está inativo
        ]
      ]
      stop
    ]

    ; Memória do patch atual
    let patch-atual patch-here
    let tempo-desde-limpeza ticks - [tempo-limpo] of patch-atual
    let patches-atuais filter [p -> ticks - last p < 50] patches-recentes
    set patches-recentes patches-atuais

    ; Atualiza a memória do patch atual
    let patch-na-memoria filter [m -> first m = patch-atual] patches-recentes
    ifelse not empty? patch-na-memoria [
      let posicao position first patch-na-memoria patches-recentes
      set patches-recentes replace-item posicao patches-recentes (list patch-atual [sujo?] of patch-atual tempo-desde-limpeza)
    ][
      set patches-recentes lput (list patch-atual [sujo?] of patch-atual tempo-desde-limpeza) patches-recentes
    ]

    ; Otimização da busca de lixo
    let patches-vistos patches in-radius 5  ; Patches visíveis em um raio maior
    let patches-sujos patches-vistos with [sujo? and not member? self patches-recentes]  ; Patches sujos não recentemente limpos

    ifelse any? patches-sujos [
      ; Prioriza patches sujos com base no tempo de lixo (mais antigos primeiro)
      let patch-alvo max-one-of patches-sujos [tempo-limpo]
      face patch-alvo
      safe-move 1

      ; Verifica se o patch tem lixo pesada ou tóxica
      if [sujo?] of patch-alvo [
        if [tipo-de-lixo] of patch-alvo = "pesada" [
          set energia energia - (energia-inicial * 0.25)  ; Penaliza o Cleaner por passar em lixo pesada
          print (word "Passou por lixo pesada. Energia reduzida em 25%. Energia atual: " energia)
        ]
        if [tipo-de-lixo] of patch-alvo = "toxica" [
          set energia energia - (energia-inicial * 0.5)
          print (word "Passou por lixo tóxica. Energia reduzida em 50%. Energia atual: " energia)
        ]
        ; Limpar o patch
        ask patch-alvo [
          set sujo? false  ; Limpa o patch
          set pcolor white  ; Retorna a cor original do patch
          set tempo-limpo ticks
        ]
        set detritos detritos + 1  ; Atualiza a quantidade de detritos coletados
      ]
    ][
      ; Se não houver patches sujos, move-se aleatoriamente, mas evita patches recentemente visitados
      let patch-aleatorio one-of patches-vistos with [not member? self patches-recentes]
      ifelse patch-aleatorio != nobody [
        face patch-aleatorio
        safe-move 1
      ][
        ; Se não encontrar um patch novo, move-se aleatoriamente
        right random 360
        safe-move 1
      ]
    ]

    ; Reduzir a energia a cada movimento
    set energia energia - 1
    if energia <= 0 [ recarregar ]
  ]
end

; Algoritmo para exploração inteligente
to andar-explorar
  ; Ajusta o raio de exploração baseado na energia restante
  let raio-exploracao 5
  if energia < energia-inicial * 0.5 [
    print "Energia abaixo de 50%. Reduzindo raio de exploração para 3."
    set raio-exploracao 3
  ]

  ; O Cleaner examina os patches ao seu redor dentro do raio ajustado
  let patches-visiveis patches in-radius raio-exploracao
  print (word "Patches visíveis no raio de " raio-exploracao ": " count patches-visiveis)

  ; Seleciona patches que não estão na lista de patches recentes e que podem estar sujos
  let patches-validos patches-visiveis with [
    not member? (list pxcor pycor) patches-recentes
    and not deposito?
    and not painel-solar?
  ]
  print (word "Patches válidos encontrados: " count patches-validos)


  ; Se encontrar patches válidos, move-se para um deles, senão move-se aleatoriamente
  ifelse any? patches-validos [
    ; Se encontrar patches válidos, seleciona um e move-se para ele
    let patch-alvo one-of patches-validos
    print (word "Patch alvo encontrado em: (" [pxcor] of patch-alvo "," [pycor] of patch-alvo ")")

    face patch-alvo
    safe-move 1
    print (word "Movendo para patch: (" [pxcor] of patch-here "," [pycor] of patch-here ")")

    ; Atualiza a memória do patch atual
    let patch-atual patch-here
    let tempo-desde-limpeza ticks - [tempo-limpo] of patch-atual
    set patches-recentes lput (list [pxcor] of patch-atual [pycor] of patch-atual) patches-recentes
    print (word "Memória atualizada: Patch (" [pxcor] of patch-atual "," [pycor] of patch-atual ") visitado.")

  ] [
    ; Se não encontrar patches válidos, move-se aleatoriamente
    print "Nenhum patch estratégico encontrado, movendo-se aleatoriamente..."
    right random 360
    safe-move 1
    print (word "Movendo-se aleatoriamente para: (" [pxcor] of patch-here "," [pycor] of patch-here ")")
  ]
          set energia energia - 1

  ; Verifica a energia e decide se é necessário recarregar ou continuar explorando
  ifelse energia <= 0 [
    print "Energia esgotada durante a exploração. Iniciando recarga..."
    recarregar
  ] [
    print (word "Energia restante: " energia)
  ]
end


to ativar-bomba
  ifelse not bomba-usada? [   ; A bomba só pode ser usada uma vez
    set bomba-usada? true
    set bomba-temporizador 20   ; O cleaner ficará parado por 20 ticks
    let raio-limpeza 11          ; Define o raio da limpeza
    ask patches in-radius raio-limpeza [
      set sujo? false
      set pcolor white          ; Limpa e muda a cor de volta para branco
      set tempo-limpo ticks     ; Marca o tempo em que foi limpo
    ]
    print "Bomba ativada! Limpando grande área..."
  ] [
    print "Bomba ja usada..."
  ]
end






to safe-move [distancia]
  let next-x xcor + distancia * sin heading
  let next-y ycor + distancia * cos heading

  ; Verifica se o próximo movimento ultrapassará as bordas
  ifelse (next-x <= max-pxcor and next-x >= min-pxcor and next-y <= max-pycor and next-y >= min-pycor) [
    fd distancia
  ] [
    ; Se ultrapassar, não se move e talvez faça algo como girar ou recuar
    rt random 180  ; Gira aleatoriamente
  ]
end


; Função de recarregar energia
to recarregar
  move-to patch min-pxcor min-pycor
  set recarregamento? true

end
to continuar-recarregar
  ; Se o Cleaner ainda não completou o ciclo de recarregamento
  set tempo-desde-carregamento tempo-desde-carregamento + 1
  if tempo-desde-carregamento >= tempo-carregamento [
    set energia energia-inicial  ; Define a energia para o valor máximo após o tempo de recarregamento
    set recarregamento? false    ; Finaliza o recarregamento
  ]
end

; Função de descarregar detritos
to descarregar
  let patch-alvo one-of patches with [ deposito? ]
  face patch-alvo
  move-to patch-alvo
  if patch-here = patch-alvo [
    set detritos 0
  ]
end
to mover-e-poluente
  ; Encontrar patches ao redor que não estão sujos e que não são depósitos
  let patches-limpos patches in-radius 3 with [not sujo? and not deposito? ]

  ifelse any? patches-limpos [
    ; Se houver patches limpos (e sem depósitos), mover-se para um deles
    let patch-alvo one-of patches-limpos
    face patch-alvo
    fd 0.8
  ] [
    ; Se não houver patches limpos, mover-se aleatoriamente, mas evitar depósitos
    let patches-validos patches in-radius 3 with [not deposito?]
    ifelse any? patches-validos [
      let patch-aleatorio one-of patches-validos
      face patch-aleatorio
      fd 0.8
    ] [
      right random 360
      fd 0.8
    ]
  ]
  ; Deposição de lixo com probabilidade definida pelos sliders
  if not [sujo?] of patch-here and not [deposito?] of patch-here [  ; Verifica se o patch não é depósito
    let chance-deposit random-float 1
    if chance-deposit < probabilidade-depositos [
      ask patch-here [
        set sujo? true
        set tipo-de-lixo [tipo-de-poluicao] of myself
        if tipo-de-lixo = "leve" [
          set pcolor yellow  ; Poluição leve
        ]
        if tipo-de-lixo = "pesada" [
          set pcolor brown   ; Poluição pesada
        ]
        if tipo-de-lixo = "toxica" [
          set pcolor green   ; Poluição tóxica
        ]
      ]
    ]
  ]
end

to recarregar-instantaneamente
  set energia energia + ([eficiencia] of patch-here) * 10
  if energia > energia-inicial [
    set energia energia-inicial
  ]
  set recarregamento? false
end
@#$#@#$#@
GRAPHICS-WINDOW
190
57
768
636
-1
-1
17.3
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
67
63
131
96
NIL
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
47
127
145
160
Go uma vez
Go_Once
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
60
220
123
253
NIL
Go_N
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
14
268
186
301
vezes
vezes
1
1000
999.0
1
1
NIL
HORIZONTAL

SLIDER
18
332
190
365
prob-polluter-1
prob-polluter-1
0
1
0.7
0.05
1
NIL
HORIZONTAL

SLIDER
18
399
190
432
prob-polluter-2
prob-polluter-2
0
1
0.6
0.05
1
NIL
HORIZONTAL

SLIDER
0
468
172
501
prob-polluter-3
prob-polluter-3
0
1
0.1
0.05
1
NIL
HORIZONTAL

SLIDER
796
99
968
132
postos-deposito
postos-deposito
2
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
797
145
969
178
capacidade-detritos
capacidade-detritos
1
20
16.0
1
1
NIL
HORIZONTAL

SLIDER
796
46
968
79
energia-inicial
energia-inicial
0
200
200.0
1
1
NIL
HORIZONTAL

MONITOR
816
273
979
318
Numero de detritos cleaner
[detritos] of cleaner
17
1
11

MONITOR
820
336
877
381
Energia
[energia] of cleaner
17
1
11

SLIDER
796
196
968
229
tempo-carregamento
tempo-carregamento
1
50
8.0
1
1
NIL
HORIZONTAL

PLOT
798
466
998
616
Evolução do lixo
ticks
Lixo 
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Lixo" 1.0 0 -7500403 true "" ""

MONITOR
817
402
952
447
Lixo
quantidade-de-lixo
17
1
11

PLOT
992
47
1192
197
Evolução do lixo limpo
Ticks
Limpo
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"lixo limpo" 1.0 0 -16777216 true "" ""

BUTTON
1052
345
1176
378
BOOOOOOMMM
ativar-bomba
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

BUTTON
38
565
140
598
Parar musica
parar-som
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cleaner
true
14
Circle -14835848 true false 30 30 242
Circle -7500403 true false 116 116 67
Circle -955883 true false 135 135 30
Rectangle -2674135 true false 135 240 165 285
Line -2674135 false 240 225 270 255
Line -2674135 false 30 255 60 225
Line -2674135 false 45 210 15 225
Line -2674135 false 255 210 285 240
Line -2674135 false 150 30 120 0
Line -2674135 false 165 30 195 0
Circle -13345367 true false 135 240 30

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck trash
false
0
Polygon -13345367 true false 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -13345367 true false 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42
Rectangle -10899396 true false 60 90 195 195
Rectangle -10899396 true false 15 150 60 195
Rectangle -10899396 true false 15 90 60 105

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
