# ADR 0003 — CI/CD com GitHub Actions

## Contexto

Com aplicação, infraestrutura (Terraform), configuração (Ansible) e manifests (Kubernetes)
já definidos em código, faltava automatizar build/teste da aplicação e publicar as
imagens que os Deployments do `k8s/base` referenciam.

## Decisões

- **Dois workflows separados**: `ci-cd.yml` (aplicação: teste Go + build/push das imagens)
  e `iac-validate.yml` (infraestrutura: `terraform validate`, `ansible-lint`,
  `kubeconform`), cada um só disparado por mudanças nos caminhos relevantes
  (`api/`+`frontend/` vs `infra/`+`k8s/`) — evita rodar build de imagem Docker por causa
  de uma mudança no Terraform, e vice-versa.
- **`iac-validate.yml` é a primeira validação real que Terraform/Ansible/k8s manifests
  recebem**: nenhuma dessas ferramentas está instalada na máquina de desenvolvimento
  (ver ADRs 0001 e 0002), então até este ponto todo o código de infraestrutura foi
  revisado só manualmente. O GitHub Actions roda `terraform fmt`/`validate` (sem
  credenciais AWS — só sintaxe/coerência dos módulos), `ansible-lint`, e `kubeconform`
  nos manifests k8s de kind nativo (o `ClusterIssuer` do cert-manager fica de fora por
  ser um CRD sem schema público disponível para o kubeconform).
- **Push de imagem só fora de Pull Request**: PRs rodam o build para validar que o
  Dockerfile ainda funciona, mas não publicam nada no GHCR — só builds vindos de um
  push real em `develop`/`main` publicam.
- **Tags por branch**: push em `develop` gera a tag `:develop` (ambiente de
  homologação); push em `main` gera `:latest` (é essa tag que os Deployments em
  `k8s/base` usam) — mantém o significado do GitFlow (main = o que está "em produção").
  Todo push também recebe uma tag com o SHA curto do commit, para rollback pontual.
- **Sem secret extra para o GHCR**: usa `${{ secrets.GITHUB_TOKEN }}`, automático em
  toda Action, com `permissions: packages: write` — não precisa de PAT manual.

## Consequência pendente

Os pacotes publicados no GHCR (`ghcr.io/guilherme-vinholes/meu-desafio-devops-bry-api`
e `-frontend`) nascem **privados** por padrão. Para os nodes do K3s conseguirem fazer
`docker pull` sem autenticação, é preciso ir em Settings do pacote no GitHub e marcar
como público (recomendado para este projeto de avaliação, sem código sensível) — ou,
alternativamente, criar um `imagePullSecrets` no namespace `bry-desafio` com um PAT.
Isso ainda não foi feito porque depende do primeiro push real acontecer primeiro (o
pacote só existe depois do primeiro build com sucesso).
