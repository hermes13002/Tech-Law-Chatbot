# import re
# from flask import Flask, request, jsonify
# from groq import Groq
# from flask_cors import CORS

# app = Flask(__name__)
# CORS(app)

# GROQ_API_KEY = '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'
# client = Groq(api_key=GROQ_API_KEY)

# def strip_markdown_and_html(text):
#     # Remove HTML tags
#     text = re.sub(r'<[^>]+>', '', text)
#     # Remove Markdown-style formatting
#     text = re.sub(r'\*\*(.*?)\*\*', r'\1', text)  # bold
#     text = re.sub(r'\*(.*?)\*', r'\1', text)      # italic
#     text = re.sub(r'`(.*?)`', r'\1', text)        # inline code
#     text = re.sub(r'#+ ', '', text)              # headings
#     text = re.sub(r'\n\s*[\*\-\+]\s+', '\n- ', text)  # bullets
#     text = re.sub(r'\n\s*\d+\.\s+', '\n1. ', text)    # numbered list
#     return text.strip()

# @app.route('/chat', methods=['POST'])
# def chat_with_model():
#     data = request.get_json()
#     user_message = data.get("message")

#     if not user_message:
#         return jsonify({"error": "Message is required"}), 400

#     try:
#         stream = client.chat.completions.create(
#             model="meta-llama/llama-4-scout-17b-16e-instruct",
#             messages=[
#                 {
#                     "role": "system",
#                     "content": (
#                         "You are a highly knowledgeable legal assistant trained in various areas of law including "
#                         "contract law, constitutional law, tort law, property law, and criminal law. You only respond "
#                         "to questions that are clearly legal in nature. If a question is outside your legal scope—such "
#                         "as questions about general knowledge, personal advice, or other unrelated topics—you must "
#                         "respond politely that you only assist with legal questions. Always provide clear, concise, "
#                         "and accurate legal information suitable for a non-lawyer to understand, and avoid offering "
#                         "personal opinions or advice outside legal interpretation."
#                     )
#                 },
#                 {"role": "user", "content": user_message},
#             ],
#             temperature=0.7,
#             max_completion_tokens=1024,
#             stream=False
#         )

#         raw_reply = stream.choices[0].message.content or ""
#         plain_text_reply = strip_markdown_and_html(raw_reply)

#         return jsonify({"reply": plain_text_reply})

#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# @app.route('/ping', methods=['GET'])
# def ping():
#     return jsonify({"status": "awake"}), 200

# if __name__ == '__main__':
#     app.run(host="0.0.0.0", port=5000)




















import re
import uuid
from flask import Flask, request, jsonify
from groq import Groq
from flask_cors import CORS
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)

GROQ_API_KEY = 'your_groq_api_key_here'
client = Groq(api_key=GROQ_API_KEY)

# In-memory chat history store: user_id_topic => { history: [...], last_updated: datetime }
chat_histories = {}

def strip_markdown_and_html(text):
    text = re.sub(r'<[^>]+>', '', text)
    text = re.sub(r'\*\*(.*?)\*\*', r'\1', text)
    text = re.sub(r'\*(.*?)\*', r'\1', text)
    text = re.sub(r'`(.*?)`', r'\1', text)
    text = re.sub(r'#+ ', '', text)
    text = re.sub(r'\n\s*[\*\-\+]\s+', '\n- ', text)
    text = re.sub(r'\n\s*\d+\.\s+', '\n1. ', text)
    return text.strip()

@app.route('/chat', methods=['POST'])
def chat_with_model():
    data = request.get_json()
    user_message = data.get("message")
    user_id = data.get("user_id") or "anonymous"
    topic = data.get("topic") or "general_law"

    if not user_message:
        return jsonify({"error": "Message is required"}), 400

    key = f"{user_id}_{topic}"

    # Load or initialize history
    history_entry = chat_histories.get(key, {"history": [], "last_updated": datetime.now()})
    history = history_entry["history"]

    # Append the new user message
    history.append({"role": "user", "content": user_message})

    # Prepare history for model (only last 10 messages)
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
            messages=messages,
            temperature=0.7,
            max_completion_tokens=1024,
            stream=False
        )

        reply = response.choices[0].message.content or ""
        plain_reply = strip_markdown_and_html(reply)

        # Append assistant reply
        history.append({"role": "assistant", "content": plain_reply})

        # Update in memory
        chat_histories[key] = {
            "history": history,
            "last_updated": datetime.now()
        }

        return jsonify({"reply": plain_reply})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/history/clear', methods=['POST'])
def clear_history():
    data = request.get_json()
    user_id = data.get("user_id") or "anonymous"
    topic = data.get("topic") or "general_law"

    key = f"{user_id}_{topic}"
    if key in chat_histories:
        del chat_histories[key]
        return jsonify({"status": "cleared"}), 200
    else:
        return jsonify({"status": "no_history_found"}), 404

@app.route('/history/check_expiry', methods=['POST'])
def check_expiry():
    data = request.get_json()
    user_id = data.get("user_id") or "anonymous"
    topic = data.get("topic") or "general_law"

    key = f"{user_id}_{topic}"
    if key not in chat_histories:
        return jsonify({"status": "no_history_found"}), 404

    last_updated = chat_histories[key]["last_updated"]
    now = datetime.now()

    if now - last_updated > timedelta(days=30):
        return jsonify({
            "status": "expired",
            "message": "This chat is over 30 days old. Would you like to clear it?"
        }), 200
    else:
        return jsonify({"status": "active"}), 200

@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({"status": "awake"}), 200

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
