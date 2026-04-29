from flask import Flask, render_template, request, jsonify, session
from trust_game import TrustGame
import random

app = Flask(__name__)
app.secret_key = 'your_secret_key_here'  # Required for using session

# Global game conditions
CONDITIONS = ['A', 'B', 'C', 'Salary_Increase']

@app.route('/')
def home():
    """
    Render the home page with the current game condition.
    """
    # Assign a random condition per user session
    if 'condition' not in session:
        session['condition'] = random.choice(CONDITIONS)
    
    return render_template('index.html', condition=session['condition'])

@app.route('/play', methods=['POST'])
def play_game():
    """
    Play the Trust Game based on buyer and seller decisions.
    """
    data = request.get_json()
    buyer_choice = data.get('buyer_choice')
    seller_choice = data.get('seller_choice', None)
    
    if buyer_choice not in ["Trust", "Not trust"]:
        return jsonify({'error': 'Invalid buyer choice'}), 400
    if seller_choice not in ["Honor", "Abuse", None]:
        return jsonify({'error': 'Invalid seller choice'}), 400
    
    # Initialize game with the current session's condition
    game = TrustGame(session['condition'])
    
    # Game logic based on the current stage
    if seller_choice is None:
        # Waiting for seller's decision after buyer trusts
        if buyer_choice == "Not trust":
            result = game.calculate_decision_payoff(buyer_choice, None)
        else:
            result = {"stage": "seller", "message": "Waiting for seller's decision..."}
    else:
        # Complete the trust game decision cycle
        result = game.calculate_decision_payoff(buyer_choice, seller_choice)
    
    return jsonify({
        **result,
        'condition': session['condition']
    })

if __name__ == '__main__':
    app.run(debug=True)
