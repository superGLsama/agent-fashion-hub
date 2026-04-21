"""
AI Agent 潮流平台 - Python 后端示例
使用 Flask + MySQL 实现 RESTful API

日期: 2026-04-09
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import pymysql
from pymysql.cursors import DictCursor
import json
from datetime import datetime

app = Flask(__name__)
CORS(app)

# =============================================
# 数据库配置
# =============================================
DB_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': 'your_password',
    'database': 'agent_fashion_hub',
    'charset': 'utf8mb4',
    'cursorclass': DictCursor
}

def get_db_connection():
    """获取数据库连接"""
    return pymysql.connect(**DB_CONFIG)

# =============================================
# 数据模型类
# =============================================

class Product:
    """产品模型"""
    
    @staticmethod
    def get_all(filters=None):
        """获取所有产品"""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                sql = "SELECT * FROM products WHERE is_active = 1"
                params = []
                
                if filters:
                    if filters.get('rarity'):
                        sql += " AND rarity = %s"
                        params.append(filters['rarity'])
                    if filters.get('alliance_id'):
                        sql += " AND alliance_id = %s"
                        params.append(filters['alliance_id'])
                
                sql += " ORDER BY FIELD(rarity, 'legendary', 'epic', 'rare', 'common'), price DESC"
                cursor.execute(sql, params)
                return cursor.fetchall()
        finally:
            conn.close()
    
    @staticmethod
    def get_by_id(product_id):
        """根据ID获取产品"""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                sql = "SELECT * FROM products WHERE id = %s"
                cursor.execute(sql, (product_id,))
                return cursor.fetchone()
        finally:
            conn.close()

class User:
    """用户模型"""
    
    @staticmethod
    def get_by_id(user_id):
        """获取用户信息"""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                sql = """
                    SELECT u.*, a.name as alliance_name, a.icon as alliance_icon
                    FROM users u
                    LEFT JOIN alliances a ON u.alliance_id = a.id
                    WHERE u.id = %s
                """
                cursor.execute(sql, (user_id,))
                return cursor.fetchone()
        finally:
            conn.close()
    
    @staticmethod
    def update_points(user_id, change_amount, reason):
        """更新用户积分"""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                # 扣减积分
                sql = "UPDATE users SET points = points + %s WHERE id = %s AND points + %s >= 0"
                affected = cursor.execute(sql, (change_amount, user_id, change_amount))
                
                if affected == 0:
                    return False
                
                # 获取更新后的余额
                cursor.execute("SELECT points FROM users WHERE id = %s", (user_id,))
                new_balance = cursor.fetchone()['points']
                
                # 记录积分变动
                cursor.execute("""
                    INSERT INTO points_log (user_id, change_amount, balance_after, reason)
                    VALUES (%s, %s, %s, %s)
                """, (user_id, change_amount, new_balance, reason))
                
                conn.commit()
                return True
        finally:
            conn.close()

class UserItem:
    """用户物品模型"""
    
    @staticmethod
    def add_item(user_id, item_type, item_id):
        """添加物品到用户背包"""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                # 检查是否已拥有
                cursor.execute("""
                    SELECT id, quantity FROM user_items 
                    WHERE user_id = %s AND item_type = %s AND item_id = %s
                """, (user_id, item_type, item_id))
                existing = cursor.fetchone()
                
                if existing:
                    # 增加数量
                    cursor.execute("""
                        UPDATE user_items SET quantity = quantity + 1 
                        WHERE id = %s
                    """, (existing['id'],))
                else:
                    # 新增记录
                    cursor.execute("""
                        INSERT INTO user_items (user_id, item_type, item_id)
                        VALUES (%s, %s, %s)
                    """, (user_id, item_type, item_id))
                
                conn.commit()
                return True
        finally:
            conn.close()
    
    @staticmethod
    def get_user_items(user_id, item_type=None):
        """获取用户物品列表"""
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                if item_type == 'product':
                    sql = """
                        SELECT ui.*, p.name, p.icon, p.rarity, p.bonus_stats,
                               p.description, 'product' as type_name
                        FROM user_items ui
                        JOIN products p ON ui.item_id = p.id
                        WHERE ui.user_id = %s AND ui.item_type = 'product'
                    """
                elif item_type == 'agent':
                    sql = """
                        SELECT ui.*, a.name, a.icon, a.rarity, a.stats,
                               a.description, 'agent' as type_name
                        FROM user_items ui
                        JOIN agents a ON ui.item_id = a.id
                        WHERE ui.user_id = %s AND ui.item_type = 'agent'
                    """
                else:
                    # 获取所有物品
                    sql = f"""
                        SELECT ui.*, p.name, p.icon, p.rarity, p.bonus_stats,
                               p.description, 'product' as type_name
                        FROM user_items ui
                        JOIN products p ON ui.item_id = p.id
                        WHERE ui.user_id = %s AND ui.item_type = 'product'
                        UNION ALL
                        SELECT ui.*, a.name, a.icon, a.rarity, a.stats,
                               a.description, 'agent' as type_name
                        FROM user_items ui
                        JOIN agents a ON ui.item_id = a.id
                        WHERE ui.user_id = %s AND ui.item_type = 'agent'
                    """
                
                cursor.execute(sql, (user_id, user_id) if not item_type else (user_id,))
                return cursor.fetchall()
        finally:
            conn.close()

# =============================================
# API 路由
# =============================================

@app.route('/api/products', methods=['GET'])
def get_products():
    """获取产品列表"""
    filters = {
        'rarity': request.args.get('rarity'),
        'alliance_id': request.args.get('alliance_id')
    }
    products = Product.get_all(filters)
    return jsonify({'code': 0, 'data': products})

@app.route('/api/products/<int:product_id>', methods=['GET'])
def get_product(product_id):
    """获取单个产品详情"""
    product = Product.get_by_id(product_id)
    if not product:
        return jsonify({'code': 404, 'msg': '产品不存在'}), 404
    return jsonify({'code': 0, 'data': product})

@app.route('/api/user/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """获取用户信息"""
    user = User.get_by_id(user_id)
    if not user:
        return jsonify({'code': 404, 'msg': '用户不存在'}), 404
    return jsonify({'code': 0, 'data': user})

@app.route('/api/user/<int:user_id>/items', methods=['GET'])
def get_user_items(user_id):
    """获取用户物品"""
    item_type = request.args.get('type')
    items = UserItem.get_user_items(user_id, item_type)
    return jsonify({'code': 0, 'data': items})

@app.route('/api/purchase', methods=['POST'])
def purchase():
    """购买物品"""
    data = request.get_json()
    user_id = data.get('user_id')
    item_type = data.get('item_type')  # 'product' or 'agent'
    item_id = data.get('item_id')
    
    # 获取物品信息
    if item_type == 'product':
        item = Product.get_by_id(item_id)
    else:
        # Agent 获取类似逻辑
        conn = get_db_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM agents WHERE id = %s", (item_id,))
            item = cursor.fetchone()
        conn.close()
    
    if not item:
        return jsonify({'code': 404, 'msg': '物品不存在'}), 404
    
    # 扣除积分
    if not User.update_points(user_id, -item['price'], f'购买{item["name"]}'):
        return jsonify({'code': 400, 'msg': '积分不足'}), 400
    
    # 添加物品到背包
    UserItem.add_item(user_id, item_type, item_id)
    
    return jsonify({
        'code': 0, 
        'msg': '购买成功',
        'data': {
            'item': item,
            'remaining_points': User.get_by_id(user_id)['points']
        }
    })

@app.route('/api/alliances', methods=['GET'])
def get_alliances():
    """获取所有联盟"""
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM alliances ORDER BY id")
            alliances = cursor.fetchall()
            return jsonify({'code': 0, 'data': alliances})
    finally:
        conn.close()

# =============================================
# 启动
# =============================================

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
