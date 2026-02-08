# Helpdesk de Manutenção - PROJETO DE EXTENSÃO

Este projeto consiste na modelagem e implementação de um sistema de **Helpdesk e Gestão de Ativos** desenvolvido para otimizar as manutenções corretivas e preventivas de órgãos públicos.

### 🎯 Objetivos do Projeto

- **Gestão de Ativos:** Controle total sobre equipamentos (ar-condicionado, informática, etc.) vinculados a patrimônios específicos.
- **Continuidade do Serviço:** Regras de visibilidade por setor que garantem que o trabalho não pare durante férias ou faltas de colegas.
- **Manutenção Preventiva:** Automatização de agendamentos para evitar falhas em equipamentos críticos.
- **Transparência e Auditoria:** Registro detalhado de logs, histórico de status e diário de bordo técnico.

### 🛠️ Tecnologias Utilizadas

- **Banco de Dados:** MySQL 8.0
- **Modelagem:** MySQL Workbench
- **Segurança:** Implementação de Multi-tenancy (isolamento de dados por instituição) e Hash de senhas.

### 📂 Estrutura do Banco de Dados

O sistema conta com quase 30 tabelas organizadas nos seguintes módulos:

1. **Núcleo de Identidade:** Gestão de Instituições (Tenants), Usuários, Departamentos e Permissões (Roles).
2. **Operação de Chamados:** Tickets, Comentários (Diário de bordo), Anexos e Tags.
3. **Gestão de SLA:** Políticas de prazos e calendários de funcionamento.
4. **Patrimônio:** Inventário de Bens (Assets) e Agendamentos de Manutenção.
5. **Logística:** Registro de horas trabalhadas (Work Logs), Deslocamento (KM) e uso de peças (Insumos).

### 🚀 Como utilizar

1. Certifique-se de ter o **MySQL Server** instalado.
2. Importe o arquivo `script_banco.sql` localizado na raiz deste projeto.

---

## 🖼️ Galeria de Módulos do Sistema

Os diagramas de Entidade-Relacionamento (DER) abaixo estão organizados por **responsabilidade lógica**, refletindo a arquitetura modular do sistema.

### 1. Módulo de Identidade e Acesso (IAM)

Responsável pelo **multi-tenancy**, gestão de usuários, setores e perfis de acesso.  
Garante o isolamento entre instituições, controle de permissões e segurança no processo de autenticação.

### 2. Módulo de Operações (Core)

Núcleo do sistema, onde ocorre o **ciclo completo dos chamados**: abertura, categorização, interação, atribuição, acompanhamento e encerramento.

### 3. Módulo de Patrimônio e Manutenção

Gerencia o **inventário de bens (Assets)** e os **agendamentos de manutenção preventiva e corretiva**, incluindo a geração automática de chamados a partir da execução das manutenções.

### 4. Módulo de Governança e Performance (SLA)

Responsável pelo **histórico de mudanças de status**, auditoria de ações e monitoramento do cumprimento de **prazos e níveis de serviço (SLA)**.

### 5. Módulo de Logística e Recursos (Fulfillment)

Dá suporte à execução operacional, contemplando a **gestão de equipes técnicas**, registro de deslocamentos (quilometragem) e **controle de materiais e peças utilizadas**.

### 💡 Observação de Arquitetura

A separação do sistema em módulos independentes facilita a **escalabilidade**, **manutenção**, **auditoria** e a evolução contínua de cada domínio funcional.
