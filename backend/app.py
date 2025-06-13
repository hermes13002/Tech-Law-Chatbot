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


from flask import Flask, request, jsonify, Response, stream_with_context
from groq import Groq
from flask_cors import CORS
from bs4 import BeautifulSoup
import os

app = Flask(__name__)
CORS(app)

GROQ_API_KEY = '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'
client = Groq(api_key=GROQ_API_KEY)

@app.route('/chat', methods=['POST'])
def chat_with_model():
    data = request.get_json()
    user_message = data.get("message")

    if not user_message:
        return jsonify({"error": "Message is required"}), 400

    def generate():
        try:
            stream = client.chat.completions.create(
                model="meta-llama/llama-4-scout-17b-16e-instruct",
                messages=[
                    {
                        "role": "system", 
                        "content": (
                            "You are a highly knowledgeable legal assistant trained in various areas of law including "
                            "contract law, constitutional law, tort law, property law, and criminal law. You only respond "
                            "to questions that are clearly legal in nature..."
                        )
                    },
                    {"role": "user", "content": user_message},
                ],
                temperature=0.7,
                max_completion_tokens=1024,
                stream=True
            )

            for chunk in stream:
                delta = chunk.choices[0].delta
                content = delta.content if hasattr(delta, "content") else ""
                safe_content = content if content is not None else ""
                text = BeautifulSoup(safe_content, "html.parser").get_text()
                yield text

        except Exception as e:
            yield f"[ERROR] {str(e)}"

    return Response(stream_with_context(generate()), mimetype='text/event-stream', content_type='text/plain')

@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({"status": "awake"}), 200

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
