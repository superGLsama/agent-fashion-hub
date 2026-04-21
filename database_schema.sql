-- =============================================
-- AI Agent 潮流平台 - MySQL 数据库设计
-- 版本: 1.0
-- 日期: 2026-04-09
-- =============================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS agent_fashion_hub 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE agent_fashion_hub;

-- =============================================
-- 1. 用户表
-- =============================================
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT COMMENT '用户ID',
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    nickname VARCHAR(100) COMMENT '昵称',
    avatar VARCHAR(255) DEFAULT '/assets/default-avatar.png' COMMENT '头像URL',
    points INT DEFAULT 0 COMMENT '用户积分',
    vip_level TINYINT DEFAULT 0 COMMENT 'VIP等级 0-10',
    alliance_id INT COMMENT '所属联盟ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    last_login_at DATETIME COMMENT '最后登录时间',
    status TINYINT DEFAULT 1 COMMENT '状态 1-正常 0-禁用',
    
    INDEX idx_alliance (alliance_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB COMMENT='用户表';

-- =============================================
-- 2. 联盟表
-- =============================================
CREATE TABLE alliances (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL COMMENT '联盟名称',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT '联盟代码 tech/nature/chaos',
    icon VARCHAR(50) COMMENT '联盟图标',
    description TEXT COMMENT '联盟描述',
    member_count INT DEFAULT 0 COMMENT '成员数量',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='联盟表';

-- 初始化联盟数据
INSERT INTO alliances (name, code, icon, description) VALUES
('科技派', 'tech', '⚡', '追求科技与效率的精英联盟'),
('自然派', 'nature', '🌿', '崇尚自然与平衡的古老联盟'),
('混沌派', 'chaos', '🔥', '拥抱变化与自由的狂野联盟');

-- =============================================
-- 3. 产品表（潮流装备）
-- =============================================
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL COMMENT '产品名称',
    icon VARCHAR(50) COMMENT '产品图标',
    description TEXT COMMENT '产品描述',
    rarity ENUM('common', 'rare', 'epic', 'legendary') NOT NULL COMMENT '稀有度',
    price INT NOT NULL COMMENT '价格（积分）',
    alliance_id INT COMMENT '所属联盟',
    bonus_stats JSON COMMENT '加成属性 JSON格式',
    tags VARCHAR(255) COMMENT '标签，逗号分隔',
    stock INT DEFAULT -1 COMMENT '库存 -1表示无限',
    is_active TINYINT DEFAULT 1 COMMENT '是否上架',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_rarity (rarity),
    INDEX idx_alliance (alliance_id),
    INDEX idx_price (price),
    INDEX idx_active (is_active)
) ENGINE=InnoDB COMMENT='产品表';

-- =============================================
-- 4. Agent 收藏表
-- =============================================
CREATE TABLE agents (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL COMMENT 'Agent名称',
    icon VARCHAR(50) COMMENT 'Agent图标',
    description TEXT COMMENT '描述',
    rarity ENUM('common', 'rare', 'epic', 'legendary') NOT NULL COMMENT '稀有度',
    price INT NOT NULL COMMENT '价格',
    alliance_id INT COMMENT '所属联盟',
    stats JSON COMMENT '属性 JSON',
    is_active TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_rarity (rarity),
    INDEX idx_alliance (alliance_id)
) ENGINE=InnoDB COMMENT='Agent收藏表';

-- =============================================
-- 5. 用户拥有装备表
-- =============================================
CREATE TABLE user_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL COMMENT '用户ID',
    item_type ENUM('product', 'agent') NOT NULL COMMENT '物品类型',
    item_id INT NOT NULL COMMENT '物品ID',
    quantity INT DEFAULT 1 COMMENT '数量',
    equipped TINYINT DEFAULT 0 COMMENT '是否已穿戴',
    acquired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '获得时间',
    
    UNIQUE KEY uk_user_item (user_id, item_type, item_id),
    INDEX idx_user (user_id),
    INDEX idx_item (item_type, item_id)
) ENGINE=InnoDB COMMENT='用户拥有装备表';

-- =============================================
-- 6. 用户积分变动记录表
-- =============================================
CREATE TABLE points_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL COMMENT '用户ID',
    change_amount INT NOT NULL COMMENT '变动积分（正负）',
    balance_after INT NOT NULL COMMENT '变动后余额',
    reason VARCHAR(100) COMMENT '变动原因',
    order_no VARCHAR(64) COMMENT '关联订单号',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_user (user_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB COMMENT='积分变动记录表';

-- =============================================
-- 7. 订单表
-- =============================================
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_no VARCHAR(64) NOT NULL UNIQUE COMMENT '订单号',
    user_id INT NOT NULL COMMENT '用户ID',
    total_amount INT NOT NULL COMMENT '订单金额',
    status ENUM('pending', 'paid', 'shipped', 'completed', 'cancelled') DEFAULT 'pending',
    paid_at DATETIME COMMENT '支付时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_user (user_id),
    INDEX idx_order_no (order_no),
    INDEX idx_status (status)
) ENGINE=InnoDB COMMENT='订单表';

-- =============================================
-- 8. 订单明细表
-- =============================================
CREATE TABLE order_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL COMMENT '订单ID',
    item_type ENUM('product', 'agent') NOT NULL,
    item_id INT NOT NULL,
    price INT NOT NULL COMMENT '购买时价格',
    quantity INT DEFAULT 1,
    
    INDEX idx_order (order_id)
) ENGINE=InnoDB COMMENT='订单明细表';

-- =============================================
-- 9. 稀有度配置表
-- =============================================
CREATE TABLE rarity_config (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    color VARCHAR(20) DEFAULT '#ffffff',
    drop_rate DECIMAL(5,4) COMMENT '掉落概率',
    max_owned INT DEFAULT 1 COMMENT '最大持有数'
) ENGINE=InnoDB COMMENT='稀有度配置表';

-- 初始化稀有度配置
INSERT INTO rarity_config (code, name, color, drop_rate, max_owned) VALUES
('common', '普通', '#9ca3af', 0.6000, 99),
('rare', '稀有', '#3b82f6', 0.2500, 10),
('epic', '史诗', '#a855f7', 0.1200, 5),
('legendary', '传说', '#f59e0b', 0.0300, 1);

-- =============================================
-- 示例数据
-- =============================================

-- 添加产品
INSERT INTO products (name, icon, description, rarity, price, alliance_id, bonus_stats, tags) VALUES
('量子计算核心', '🔮', '内置量子芯片，算力提升500%', 'legendary', 3000, 1, '{"speed": 50, "intelligence": 30}', '核心装备,算力加成'),
('星辰披风', '🌌', '星际材料打造，闪烁神秘光芒', 'epic', 1500, 2, '{"charm": 20}', '外观装备,稀有布料'),
('能量护盾', '🛡️', '可伸缩能量场，防御一切攻击', 'rare', 800, 1, '{"defense": 15}', '防御装备,能量型'),
('自然之心', '🌱', '蕴含大自然的力量，生命气息浓郁', 'epic', 1200, 2, '{"recovery": 30}', '核心装备,自然能量'),
('混沌之眼', '👁️', '能够看穿一切虚假与真实', 'legendary', 3500, 3, '{"insight": 100}', '感知装备,混沌属性'),
('微型推进器', '🚀', '基础移动装置，稳定可靠', 'common', 300, 1, '{"speed": 5}', '移动装备,基础款'),
('烈焰之拳', '🔥', '燃烧着永不熄灭的火焰', 'rare', 600, 3, '{"attack": 25}', '攻击装备,火焰属性'),
('藤蔓护腕', '🌿', '来自原始森林的藤蔓编制', 'common', 200, 2, '{"tenacity": 10}', '防御装备,自然材料');

-- 添加Agent
INSERT INTO agents (name, icon, description, rarity, price, alliance_id, stats) VALUES
('Power', '🤖', '力量与智慧的结合体', 'epic', 2000, 1, '{"power": 80, "intelligence": 90}'),
('Nova', '✨', '星光凝聚而成的存在', 'legendary', 5000, 2, '{"power": 95, "charm": 95}'),
('Shadow', '👤', '行走在黑暗中的幽灵', 'rare', 1200, 3, '{"stealth": 85}'),
('Echo', '🔊', '回声中的信息体', 'rare', 1000, 1, '{"speed": 70}');

-- =============================================
-- 常用查询示例
-- =============================================

-- 1. 查询用户信息（含联盟）
-- SELECT u.*, a.name as alliance_name 
-- FROM users u 
-- LEFT JOIN alliances a ON u.alliance_id = a.id 
-- WHERE u.id = 1;

-- 2. 查询用户的装备列表
-- SELECT ui.*, p.name, p.rarity, p.icon 
-- FROM user_items ui 
-- JOIN products p ON ui.item_id = p.id 
-- WHERE ui.user_id = 1 AND ui.item_type = 'product';

-- 3. 查询某稀有度的装备
-- SELECT * FROM products 
-- WHERE rarity = 'legendary' 
-- ORDER BY price DESC;

-- 4. 查询积分变动记录
-- SELECT * FROM points_log 
-- WHERE user_id = 1 
-- ORDER BY created_at DESC 
-- LIMIT 10;

-- 5. 统计各联盟用户数量
-- SELECT a.name, COUNT(u.id) as user_count 
-- FROM alliances a 
-- LEFT JOIN users u ON a.id = u.alliance_id 
-- GROUP BY a.id;
