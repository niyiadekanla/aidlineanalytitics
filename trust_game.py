import random

class TrustGame:
    def __init__(self, condition):
        """
        Initialize the Trust Game with specific experimental conditions.
        
        Conditions:
        A: Segmented without Bonus Framing
        B: Lump Sum
        C: Segmented with Bonus Framing
        Salary Increase: Special condition with higher base salary
        """
        self.conditions = {
            'A': {
                'base_salary': 6000,
                'additional_payment': 4000,
                'payment_type': 'Segmented (Neutral)',
                'shock_probability': 0.5,
                'shock_range': (1000, 5000),
                'bonus_multiplier': 1.2,
                'penalty_multiplier': 0.5
            },
            'B': {
                'base_salary': 10000,
                'additional_payment': 0,
                'payment_type': 'Lump Sum',
                'shock_probability': 0.5,
                'shock_range': (1000, 5000),
                'bonus_multiplier': 1.2,
                'penalty_multiplier': 0.5
            },
            'C': {
                'base_salary': 6000,
                'additional_payment': 4000,
                'payment_type': 'Segmented (Bonus Framed)',
                'shock_probability': 0.5,
                'shock_range': (1000, 5000),
                'bonus_multiplier': 1.2,
                'penalty_multiplier': 0.5
            },
            'Salary_Increase': {
                'base_salary': 9000,
                'additional_payment': 4000,
                'payment_type': 'Salary Increase',
                'shock_probability': 0.3,
                'shock_range': (3000, 5000),
                'bonus_multiplier': 1.3,
                'penalty_multiplier': 0.6
            }
        }
        
        self.condition = condition
        self.config = self.conditions[condition]
        self.total_payoff = self.config['base_salary'] + self.config['additional_payment']
        
    def calculate_shock(self, initial_amount):
        """
        Apply a potential financial shock based on condition probabilities.
        """
        if random.random() < self.config['shock_probability']:
            shock_amount = random.randint(*self.config['shock_range'])
            return initial_amount - shock_amount
        return initial_amount
    
    def calculate_decision_payoff(self, buyer_choice, seller_choice):
        """
        Calculate payoff based on trust game decisions.
        
        Buyer Choices: Trust/Not Trust
        Seller Choices: Honor/Abuse
        """
        base_payoff = self.calculate_shock(self.total_payoff)
        
        if buyer_choice == "Not trust":
            return {
                'label': 'Opt-out',
                'payoff': base_payoff,
                'message': 'You chose not to engage, preserving your initial resources.'
            }
        
        if buyer_choice == "Trust" and seller_choice == "Honor":
            return {
                'label': 'Trustworthy Transaction',
                'payoff': base_payoff * self.config['bonus_multiplier'],
                'message': 'Trust leads to mutual benefit!'
            }
        
        if buyer_choice == "Trust" and seller_choice == "Abuse":
            return {
                'label': 'Trust Betrayed',
                'payoff': base_payoff * self.config['penalty_multiplier'],
                'message': 'Your trust was exploited, resulting in significant loss.'
            }
        
        return {
            'label': 'Undefined Outcome',
            'payoff': base_payoff,
            'message': 'Unexpected game scenario.'
        }
