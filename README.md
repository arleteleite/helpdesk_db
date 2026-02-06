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
