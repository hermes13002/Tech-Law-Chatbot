# from groq import Groq

# client = Groq(api_key='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')
# completion = client.chat.completions.create(
#     model="meta-llama/llama-4-scout-17b-16e-instruct",
#     messages=[
#       {
#         "role": "user",
#         "content": "What is offer and acceptance in contract law?"
#       }
#     ],
#     temperature=1,
#     max_completion_tokens=1024,
#     top_p=1,
#     stream=True,
#     stop=None,
# )

# for chunk in completion:
#     print(chunk.choices[0].delta.content or "", end="")



from flask import Flask, request, jsonify
from groq import Groq
from flask_cors import CORS
import os
import markdown2

app = Flask(__name__)
CORS(app)  # Allow requests from Flutter

GROQ_API_KEY = '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'

client = Groq(api_key=GROQ_API_KEY)

@app.route('/chat', methods=['POST'])
def chat_with_model():
    data = request.get_json()
    user_message = data.get("message")

    if not user_message:
        return jsonify({"error": "Message is required"}), 400

    try:
        stream = client.chat.completions.create(
            model="meta-llama/llama-4-scout-17b-16e-instruct",
            messages=[
                {
                    "role": "system", 
                    # "content": "You are a helpful legal assistant."
                    "content": "You are a highly knowledgeable legal assistant trained in various areas of law including contract law, constitutional law, tort law, property law, and criminal law. You only respond to questions that are clearly legal in nature. If a question is outside your legal scope—such as questions about general knowledge, personal advice, or other unrelated topics—you must respond politely that you only assist with legal questions. Always provide clear, concise, and accurate legal information suitable for a non-lawyer to understand, and avoid offering personal opinions or advice outside legal interpretation."
                },
                {"role": "user", "content": user_message},
            ],
            temperature=0.7,
            max_completion_tokens=1024,
            stream=False
        )

        # full_reply = stream.choices[0].message.content
        # return jsonify({"reply": full_reply})
    
        # Convert markdown to plain text
        full_reply = stream.choices[0].message.content or ""
        plain_text_reply = markdown2.markdown(full_reply)
        plain_text_reply = plain_text_reply.replace("<p>", "").replace("</p>", "").strip()

        return jsonify({"reply": plain_text_reply})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({"status": "awake"}), 200


if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
