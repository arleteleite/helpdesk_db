-- Banco de dados do sistema de Helpdesk
-- Charset utf8mb4 garante suporte total a caracteres especiais
CREATE DATABASE IF NOT EXISTS helpdesk_proj_extensao_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE helpdesk_proj_extensao_db;

-- Armazena as instituições (multi-tenancy)
-- Garante isolamento lógico dos dados
CREATE TABLE tenants (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    slug VARCHAR(80) NOT NULL UNIQUE,
    is_active TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Setores internos da instituição
-- Usado para organização e visibilidade de chamados
CREATE TABLE departments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(120) NOT NULL,
    code VARCHAR(30) NULL,
    cost_center_code VARCHAR(30) NULL,
    is_active TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,

    UNIQUE (tenant_id, name),

    CONSTRAINT fk_departments_tenant
        FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

-- Usuários finais, técnicos e administradores
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    department_id BIGINT NULL,
    full_name VARCHAR(160) NOT NULL,
    email VARCHAR(190) NOT NULL,
    phone VARCHAR(30) NULL,
    job_title VARCHAR(100) NULL,
    profile_picture_path VARCHAR(255) NULL,
    is_active TINYINT NOT NULL DEFAULT 1,
    must_change_password TINYINT NOT NULL DEFAULT 0,
    notify_email TINYINT NOT NULL DEFAULT 1,
    notify_push TINYINT NOT NULL DEFAULT 1,
    last_login_at DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,

    UNIQUE (tenant_id, email),

    CONSTRAINT fk_users_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_users_department FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL
);
-- ============================================================
-- TABELA: teams
-- Finalidade:
-- Armazena as equipes de atendimento do sistema de Helpdesk
-- Ex.: TI, Manutenção, Infraestrutura, Suporte Externo
-- ============================================================

CREATE TABLE teams (
    -- Identificador único da equipe
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    -- Instituição à qual a equipe pertence (multi-tenancy)
    tenant_id BIGINT NOT NULL,

    -- Nome da equipe (único por instituição)
    name VARCHAR(120) NOT NULL,

    -- Descrição opcional da função da equipe
    description VARCHAR(255) NULL,

    -- Indica se a equipe está ativa e pode receber chamados
    is_active TINYINT NOT NULL DEFAULT 1,

    -- Auditoria básica
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,

    -- Regras de integridade
    UNIQUE (tenant_id, name),

    CONSTRAINT fk_teams_tenant
        FOREIGN KEY (tenant_id)
        REFERENCES tenants(id)
        ON DELETE CASCADE
);

-- ============================================================
-- TABELA: team_members
-- Finalidade:
-- Relaciona usuários às equipes de atendimento
-- Permite definir líder técnico da equipe
-- ============================================================

CREATE TABLE team_members (
    team_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,

    -- Indica se o usuário é líder da equipe
    is_lead TINYINT NOT NULL DEFAULT 0,

    -- Auditoria
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (team_id, user_id),

    CONSTRAINT fk_tm_team
        FOREIGN KEY (team_id)
        REFERENCES teams(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_tm_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

-- Armazena apenas dados sensíveis de autenticação
CREATE TABLE auth_passwords (
    user_id BIGINT PRIMARY KEY,
    password_hash VARCHAR(255) NOT NULL,
    password_algo VARCHAR(20) NOT NULL DEFAULT 'bcrypt',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_auth_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Perfis de acesso (Admin, Técnico, Solicitante)
CREATE TABLE roles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(60) NOT NULL,
    description VARCHAR(200) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE (tenant_id, name),
    CONSTRAINT fk_roles_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

-- Associação N:N entre usuários e papéis
CREATE TABLE user_roles (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,

    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

-- Categorias hierárquicas de chamados
CREATE TABLE ticket_categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    parent_id BIGINT NULL,
    name VARCHAR(120) NOT NULL,
    default_team_id BIGINT NULL,
    is_active TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,

    UNIQUE (tenant_id, parent_id, name),

    CONSTRAINT fk_cat_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_cat_parent FOREIGN KEY (parent_id) REFERENCES ticket_categories(id) ON DELETE SET NULL
);

-- Prioridades de atendimento
CREATE TABLE ticket_priorities (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(60) NOT NULL,
    weight INT NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE (tenant_id, name),
    CONSTRAINT fk_prio_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

-- Status do ciclo de vida do chamado
CREATE TABLE ticket_statuses (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    status_key VARCHAR(30) NOT NULL,
    label VARCHAR(60) NOT NULL,
    is_final TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (tenant_id, status_key),
    CONSTRAINT fk_status_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

-- Entidade central do sistema
CREATE TABLE tickets (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ticket_number VARCHAR(30) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category_id BIGINT NOT NULL,
    priority_id BIGINT NOT NULL,
    status_id BIGINT NOT NULL,
    requester_user_id BIGINT NOT NULL,
    assigned_user_id BIGINT NULL,
    assigned_team_id BIGINT NULL,
    department_id BIGINT NOT NULL,
    channel VARCHAR(20) NOT NULL DEFAULT 'web',
    visibility VARCHAR(20) NOT NULL DEFAULT 'public',
    reopen_count INT NOT NULL DEFAULT 0,
    opened_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME NULL,
    closed_at DATETIME NULL,
    first_response_due_at DATETIME NULL,
    resolution_due_at DATETIME NULL,
    satisfaction_rating TINYINT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE (tenant_id, ticket_number),

    CONSTRAINT fk_tk_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_tk_category FOREIGN KEY (category_id) REFERENCES ticket_categories(id),
    CONSTRAINT fk_tk_priority FOREIGN KEY (priority_id) REFERENCES ticket_priorities(id),
    CONSTRAINT fk_tk_status FOREIGN KEY (status_id) REFERENCES ticket_statuses(id),
    CONSTRAINT fk_tk_requester FOREIGN KEY (requester_user_id) REFERENCES users(id),
    CONSTRAINT fk_tk_assigned_user FOREIGN KEY (assigned_user_id) REFERENCES users(id),
    CONSTRAINT fk_tk_team FOREIGN KEY (assigned_team_id) REFERENCES teams(id),
    CONSTRAINT fk_tk_dept FOREIGN KEY (department_id) REFERENCES departments(id)
);

-- Histórico de mudanças de status
CREATE TABLE ticket_status_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ticket_id BIGINT NOT NULL,
    changed_by_user_id BIGINT NULL,
    from_status_id BIGINT NULL,
    to_status_id BIGINT NOT NULL,
    note VARCHAR(255) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_hs_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_hs_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE
);

-- Comentários do chamado (públicos ou internos)
CREATE TABLE ticket_comments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ticket_id BIGINT NOT NULL,
    author_user_id BIGINT NOT NULL,
    body TEXT NOT NULL,
    is_internal TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,

    CONSTRAINT fk_tc_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_tc_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    CONSTRAINT fk_tc_author FOREIGN KEY (author_user_id) REFERENCES users(id)
);

-- Arquivos anexados aos chamados
CREATE TABLE ticket_attachments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ticket_id BIGINT NOT NULL,
    comment_id BIGINT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    file_type VARCHAR(100) NULL,
    file_size BIGINT NULL,
    uploaded_by_user_id BIGINT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ta_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_ta_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    CONSTRAINT fk_ta_comment FOREIGN KEY (comment_id) REFERENCES ticket_comments(id) ON DELETE SET NULL,
    CONSTRAINT fk_ta_user FOREIGN KEY (uploaded_by_user_id) REFERENCES users(id)
);

-- Histórico de atribuição de chamados
CREATE TABLE ticket_assignments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ticket_id BIGINT NOT NULL,
    assigned_by_user_id BIGINT NULL,
    from_assigned_user_id BIGINT NULL,
    to_assigned_user_id BIGINT NULL,
    from_team_id BIGINT NULL,
    to_team_id BIGINT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_tas_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_tas_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE
);

-- Tags livres para classificação
CREATE TABLE ticket_tags (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(50) NOT NULL,

    UNIQUE (tenant_id, name),
    CONSTRAINT fk_tag_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

-- Vínculo N:N entre chamados e tags
CREATE TABLE ticket_tag_links (
    ticket_id BIGINT NOT NULL,
    tag_id BIGINT NOT NULL,

    PRIMARY KEY (ticket_id, tag_id),
    CONSTRAINT fk_ttl_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    CONSTRAINT fk_ttl_tag FOREIGN KEY (tag_id) REFERENCES ticket_tags(id) ON DELETE CASCADE
);

-- Políticas gerais de SLA
CREATE TABLE sla_policies (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(120) NOT NULL,
    description VARCHAR(255) NULL,
    is_active TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE (tenant_id, name),
    CONSTRAINT fk_sla_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

-- Regras específicas por categoria e prioridade
CREATE TABLE sla_rules (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    sla_policy_id BIGINT NOT NULL,
    category_id BIGINT NULL,
    priority_id BIGINT NULL,
    first_response_minutes INT NOT NULL,
    resolution_minutes INT NOT NULL,
    business_hours_only TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_slar_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_slar_policy FOREIGN KEY (sla_policy_id) REFERENCES sla_policies(id) ON DELETE CASCADE,
    CONSTRAINT fk_slar_category FOREIGN KEY (category_id) REFERENCES ticket_categories(id),
    CONSTRAINT fk_slar_priority FOREIGN KEY (priority_id) REFERENCES ticket_priorities(id)
);

-- Calendários para cálculo de SLA
CREATE TABLE business_calendars (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(120) NOT NULL,
    timezone VARCHAR(50) NOT NULL DEFAULT 'America/Araguaina',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_bc_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

-- Notificações internas e externas
CREATE TABLE notifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(140) NOT NULL,
    body TEXT NULL,
    ref_entity VARCHAR(40) NULL,
    ref_id BIGINT NULL,
    read_at DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_not_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_not_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Registro de ações sensíveis do sistema
CREATE TABLE audit_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    actor_user_id BIGINT NULL,
    action VARCHAR(80) NOT NULL,
    entity VARCHAR(40) NOT NULL,
    entity_id BIGINT NULL,
    metadata_json JSON NULL,
    ip VARCHAR(45) NULL,
    user_agent VARCHAR(255) NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_audit_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

-- Sessões de autenticação (refresh tokens)
CREATE TABLE auth_sessions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    refresh_token_hash VARCHAR(255) NOT NULL,
    ip VARCHAR(45) NULL,
    user_agent VARCHAR(255) NULL,
    expires_at DATETIME NOT NULL,
    revoked_at DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sess_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_sess_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Bens e equipamentos
CREATE TABLE assets (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    asset_tag VARCHAR(60) NOT NULL,
    name VARCHAR(160) NOT NULL,
    serial_number VARCHAR(80) NULL,
    location VARCHAR(160) NULL,
    department_id BIGINT NULL,
    is_active TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,

    UNIQUE (tenant_id, asset_tag),
    CONSTRAINT fk_asset_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_asset_cat FOREIGN KEY (category_id) REFERENCES ticket_categories(id),
    CONSTRAINT fk_asset_dept FOREIGN KEY (department_id) REFERENCES departments(id)
);

-- Manutenções preventivas
CREATE TABLE maintenance_schedules (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    asset_id BIGINT NOT NULL,
    scheduled_date DATE NOT NULL,
    description VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDENTE',
    generated_ticket_id BIGINT NULL,
    assigned_user_id BIGINT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_ms_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_ms_asset FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
    CONSTRAINT fk_ms_ticket FOREIGN KEY (generated_ticket_id) REFERENCES tickets(id) ON DELETE SET NULL,
    CONSTRAINT fk_ms_user FOREIGN KEY (assigned_user_id) REFERENCES users(id)
);

-- Registro de trabalho executado
CREATE TABLE ticket_work_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ticket_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NULL,
    travel_km DECIMAL(10,2) DEFAULT 0.00,
    description TEXT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_tw_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_tw_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    CONSTRAINT fk_tw_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Peças e insumos
CREATE TABLE parts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(120) NOT NULL,
    sku VARCHAR(50) NULL,
    unit_price DECIMAL(10,2) DEFAULT 0.00,
    current_stock INT DEFAULT 0,
    min_stock INT DEFAULT 0,
    is_active TINYINT NOT NULL DEFAULT 1,

    CONSTRAINT fk_parts_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

-- Peças utilizadas nos chamados
CREATE TABLE ticket_parts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    ticket_id BIGINT NOT NULL,
    part_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    requested_by_user_id BIGINT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'REQUESTED',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_tp_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
    CONSTRAINT fk_tp_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    CONSTRAINT fk_tp_part FOREIGN KEY (part_id) REFERENCES parts(id),
    CONSTRAINT fk_tp_user FOREIGN KEY (requested_by_user_id) REFERENCES users(id)
);














