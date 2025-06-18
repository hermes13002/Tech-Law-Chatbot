import re
import uuid
from flask import Flask, request, jsonify
from groq import Groq
from flask_cors import CORS
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)

# ======================= MongoDB Setup ======================
from pymongo import MongoClient

# For local MongoDB
# client = MongoClient("mongodb://localhost:27017/")
# For Atlas, use your connection string:
client = MongoClient("mongodb+srv://soaresayoigbala:Excelsior13$@techlawcluster1.4oil6yw.mongodb.net/")

db = client["law_chatbot_db"]  # Database name
users_col = db["users"]    

# ====================== Groq API Setup ======================
from dotenv import load_dotenv
import os

load_dotenv()
GROQ_API_KEY = os.getenv('GROQ_API_KEY')

client = Groq(api_key=GROQ_API_KEY)

def strip_markdown_and_html(text):
    text = re.sub(r'<[^>]+>', '', text)
    text = re.sub(r'\*\*(.*?)\*\*', r'\1', text)
    text = re.sub(r'\*(.*?)\*', r'\1', text)
    text = re.sub(r'`(.*?)`', r'\1', text)
    text = re.sub(r'#+ ', '', text)
    text = re.sub(r'\n\s*[\*\-\+]\s+', '\n- ', text)
    text = re.sub(r'\n\s*\d+\.\s+', '\n1. ', text)
    return text.strip()

# ====================== Helper Functions ======================
def get_user_doc(user_id):
    user = users_col.find_one({"user_id": user_id})
    return user

def upsert_user_doc(user_id):
    users_col.update_one(
        {"user_id": user_id},
        {"$setOnInsert": {"user_id": user_id, "chats": []}},
        upsert=True
    )

def get_chat_index(user_doc, topic):
    for idx, chat in enumerate(user_doc.get("chats", [])):
        if chat["topic"] == topic:
            return idx
    return None

def add_or_update_chat(user_id, topic, message, role):
    user_doc = get_user_doc(user_id)
    if not user_doc:
        upsert_user_doc(user_id)
        user_doc = get_user_doc(user_id)
    if not user_doc:
        chats = []
    else:
        chats = user_doc.get("chats", [])
    chat_idx = get_chat_index(user_doc, topic)
    now = datetime.utcnow()
    if chat_idx is not None:
        # Update existing chat
        chats[chat_idx]["history"].append({"role": role, "content": message})
        chats[chat_idx]["last_updated"] = now
    else:
        # Add new chat
        chats.append({
            "topic": topic,
            "history": [{"role": role, "content": message}],
            "last_updated": now
        })
    users_col.update_one(
        {"user_id": user_id},
        {"$set": {"chats": chats}}
    )

def get_chat_history(user_id, topic):
    user_doc = get_user_doc(user_id)
    if not user_doc:
        return []
    for chat in user_doc.get("chats", []):
        if chat["topic"] == topic:
            return chat["history"]
    return []

def get_all_chats(user_id):
    user_doc = get_user_doc(user_id)
    if not user_doc:
        return {}
    return {chat["topic"]: chat["history"] for chat in user_doc.get("chats", [])}

def clear_chat_history(user_id, topic):
    user_doc = get_user_doc(user_id)
    if not user_doc:
        return False
    chats = [chat for chat in user_doc.get("chats", []) if chat["topic"] != topic]
    users_col.update_one(
        {"user_id": user_id},
        {"$set": {"chats": chats}}
    )
    return True

def get_last_updated(user_id, topic):
    user_doc = get_user_doc(user_id)
    if not user_doc:
        return None
    for chat in user_doc.get("chats", []):
        if chat["topic"] == topic:
            return chat.get("last_updated")
    return None

# ====================== Chat Endpoint ======================
@app.route('/chat', methods=['POST'])
def chat_with_model():
    data = request.get_json()
    user_message = data.get("message")
    user_id = data.get("user_id") or "anonymous"
    topic = data.get("topic") or "general_law"

    if not user_message:
        return jsonify({"error": "Message is required"}), 400

    # Append the new user message
    add_or_update_chat(user_id, topic, user_message, "user")

    # Prepare history for model (only last 10 messages)
    history = get_chat_history(user_id, topic)
    messages = [{"role": "system", "content": (
        "You are a highly knowledgeable legal assistant trained in various areas of law including "
        "contract law, constitutional law, tort law, property law, and criminal law. You only respond "
        "to questions that are clearly legal in nature. If a question is outside your legal scope—such "
        "as questions about general knowledge, personal advice, or other unrelated topics—you must "
        "respond politely that you only assist with legal questions."
    )}] + history[-10:]  # include last 10 turns

    try:
        response = client.chat.completions.create(
            model="meta-llama/llama-4-scout-17b-16e-instruct",
            messages=messages, # type: ignore
            temperature=0.7,
            max_completion_tokens=1024,
            stream=False
        ) # type: ignore

        reply = response.choices[0].message.content or ""
        plain_reply = strip_markdown_and_html(reply)

        # Append assistant reply
        add_or_update_chat(user_id, topic, plain_reply, "assistant")

        return jsonify({"reply": plain_reply})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ====================== Chat History Management ======================
@app.route('/chat_history', methods=['GET'])
def chat_history():
    try:
        user_id = request.args.get("user_id")
        if not user_id:
            return jsonify({"error": "user_id is required"}), 400

        user_chats = get_all_chats(user_id)
        return jsonify({"chats": user_chats}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ====================== User ID Management ======================
@app.route('/user_id', methods=['GET'])
def get_user_id():
    try:
        new_id = str(uuid.uuid4())
        return jsonify({"user_id": new_id}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ====================== Clear Chat History ======================
@app.route('/history/clear', methods=['POST'])
def clear_history():
    data = request.get_json()
    user_id = data.get("user_id") or "anonymous"
    topic = data.get("topic") or "general_law"

    cleared = clear_chat_history(user_id, topic)
    if cleared:
        return jsonify({"status": "cleared"}), 200
    else:
        return jsonify({"status": "no_history_found"}), 404

# ====================== Check Expiry of Chat History ======================
@app.route('/history/check_expiry', methods=['POST'])
def check_expiry():
    data = request.get_json()
    user_id = data.get("user_id") or "anonymous"
    topic = data.get("topic") or "general_law"

    last_updated = get_last_updated(user_id, topic)
    if last_updated is None:
        return jsonify({"status": "no_history_found"}), 404

    now = datetime.utcnow()
    if isinstance(last_updated, str):
        last_updated = datetime.fromisoformat(last_updated)
    if now - last_updated > timedelta(days=30):
        return jsonify({
            "status": "expired",
            "message": "This chat is over 30 days old. Would you like to clear it?"
        }), 200
    else:
        return jsonify({"status": "active"}), 200

# ====================== Health Check ======================
@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({"status": "awake"}), 200

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)