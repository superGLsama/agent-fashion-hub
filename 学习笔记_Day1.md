# 企业级开发学习 Day1

**日期：** 2026-04-09  
**主题：** MySQL + Python + Vue 入门 & 实战项目

---

## 📚 学习笔记

### 1. MySQL 基础

**建表语句核心：**
```sql
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    rarity ENUM('common', 'rare', 'epic', 'legendary'),
    points_cost INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引提升查询速度
CREATE INDEX idx_rarity ON products(rarity);
```

**查询基础：**
```sql
SELECT * FROM products WHERE rarity = 'legendary' ORDER BY points_cost DESC;
```

### 2. Python 基础

```python
# 数据结构
agent = {
    "name": "Power",
    "rarity": "epic",
    "points": 5000,
    "outfit": ["机械臂", "能量剑"]
}

# 类定义
class Product:
    def __init__(self, name, rarity, points):
        self.name = name
        self.rarity = rarity
        self.points = points
    
    def display(self):
        return f"{self.name} - {self.rarity} - {self.points}积分"
```

### 3. Vue 入门

```javascript
// Vue 3 Composition API
import { ref, computed } from 'vue'

const agents = ref([])
const userPoints = ref(1000)

const legendaryAgents = computed(() => 
    agents.value.filter(a => a.rarity === 'legendary')
)

function claimAgent(agent) {
    if (userPoints.value >= agent.points_cost) {
        userPoints.value -= agent.points_cost
    }
}
```

---

## 🎯 实战项目：AI Agent 潮流产品展示平台

### 项目概述
一个展示 AI Agent 潮流装备的平台，包含积分系统、穿搭效果、稀有度系统、Agent联盟参与功能。

### 核心功能
1. **积分系统** - 用户积分获取与消费
2. **穿搭效果** - Agent 装备展示与搭配
3. **稀有度系统** - Common/Rare/Epic/Legendary 四级稀有度
4. **Agent联盟** - 不同 Agent 阵营展示

### 技术栈
- 前端：HTML5 + CSS3 + JavaScript（单文件可运行）
- 后端模拟：JavaScript 数据结构
- 数据库设计：MySQL 表结构设计

---
