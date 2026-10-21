# Rádio Davar Chai — como colocar no ar

O app já funciona em **modo demonstração** (dados só no aparelho). Siga os 4 passos para deixá-lo online para todo mundo, de graça.

## 1. Player da rádio (Caster.fm) — ✅ FEITO
- O app já está configurado com o player da Rádio Davar Chai (publicToken `594a9a29-…`).
- Página reserva da rádio: https://radiodavarchai.ismyradio.com (aparece como link embaixo do player).
- O player só toca quando o app está publicado (passo 3); na prévia do Claude ele não carrega.

## 2. Banco de dados (Supabase, grátis)
1. Crie uma conta em https://supabase.com → **New project** (região: São Paulo).
2. Vá em **SQL Editor → New query**, cole todo o arquivo `supabase-schema.sql` e clique **Run**.
3. Em **Project Settings → API**, copie a *Project URL* e a chave *anon public*.
4. Cole em `SUPABASE_URL` e `SUPABASE_ANON_KEY` no `index.html`. (A chave anon é pública por natureza; as regras de privacidade estão no banco.)
5. Em **Authentication → URL Configuration**, coloque o endereço do seu site (passo 3) em *Site URL*.

## 3. Publicar o app (GitHub Pages, grátis)
1. Crie um repositório novo no GitHub (ex.: `radio`).
2. Envie todos os arquivos desta pasta (Add file → Upload files).
3. **Settings → Pages → Branch: main → Save**.
4. Em 1–2 minutos o app estará em `https://SEU-USUARIO.github.io/radio/`.

## 4. Montar a equipe
1. Cadastre-se no app com seu e-mail.
2. No Supabase (SQL Editor), rode a linha do final do `supabase-schema.sql` com o seu e-mail para virar **equipe**.
3. Ao entrar, aparece **Painel da equipe**: publicar devocionais (dá para agendar dias futuros), publicar estudos e ver todos os pedidos, inclusive os privados.

## Como os ouvintes instalam
- **Android:** abrir o link no Chrome → menu ⋮ → *Adicionar à tela inicial*.
- **iPhone:** abrir no Safari → Compartilhar → *Adicionar à Tela de Início*.

## O que está pronto
- Rádio 24h com programação do dia e destaque do que está no ar
- Devocional diário (versículo, meditação, pergunta e oração) com histórico
- Estudos bíblicos com contexto histórico, explicação e perguntas para grupo
- Pedidos de oração: a pessoa escolhe mural público ou só a equipe; botão "Orei por você" com contador
- Cadastro gratuito por e-mail; painel da equipe protegido pelo banco

## Testemunhos
- Qualquer ouvinte cadastrado envia um testemunho (nome, cidade, tema, título e texto) e pode autorizar que seja lido na rádio.
- Ele fica **em análise** até a equipe aprovar no Painel da equipe; só então aparece para todos.
- Quem já tem o banco criado: rode no SQL Editor só o bloco "TESTEMUNHOS" do `supabase-schema.sql`.
