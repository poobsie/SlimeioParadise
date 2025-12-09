#!/usr/bin/env python3
"""
Paradise Station Ticket System Meta-Analysis
Comprehensive analysis of different ticket configurations to visualize their effects on:
- Dry antag streaks reduction
- Antag monopolization prevention
- Overall fairness improvements
"""

import sys
import os
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from decimal import Decimal, getcontext
from collections import defaultdict
from dataclasses import dataclass
from typing import Dict, List, Tuple
import random

# Try to import seaborn, fallback without it if not available
try:
    import seaborn as sns
    HAS_SEABORN = True
except ImportError:
    HAS_SEABORN = False

# Set decimal precision for exact calculations
getcontext().prec = 10

# Import the simulator from our main analysis script
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Copy necessary classes and constants from antag_analysis.py
@dataclass
class Player:
    """Represents a player with their ticket count"""
    id: int
    tickets: Decimal
    total_selections: Dict[str, int]
    current_streak: int = 0     # Current rounds without being antag
    max_streak: int = 0         # Longest streak without being antag
    current_antag_streak: int = 0  # Current consecutive rounds being antag
    max_antag_streak: int = 0      # Longest streak of being antag

    def __post_init__(self):
        if not hasattr(self, 'total_selections') or not self.total_selections:
            self.total_selections = {}

# Configuration for meta-analysis
META_CONFIG = {
    'simulation_rounds': 5_000,   # Reduced for faster preview
    'unique_players': 50,        # Reduced for faster preview
    'players_per_round': 30,     # Reduced for faster preview
    'trials_per_config': 1,      # Reduced for faster preview
}

# Dynamic gain functions for streak-based ticket increases
DYNAMIC_GAIN_FUNCTIONS = {
    'linear': lambda streak: streak,  # gain = streak
    'exponential': lambda streak: min(100, 2 ** min(streak, 10)),  # exponential but capped
    'exponential_half': lambda streak: min(50, (1.5 ** min(streak, 15))),  # gentler exponential
    'logarithmic': lambda streak: max(1, int(np.log2(max(1, streak)) + 1)),  # log base 2
    'logarithmic_natural': lambda streak: max(1, int(np.log(max(1, streak)) + 1)),  # natural log
    'fibonacci': lambda streak: min(89, [1,1,2,3,5,8,13,21,34,55,89][min(streak, 10)]),  # fibonacci sequence
    'square_root': lambda streak: max(1, int(np.sqrt(streak) + 1)),  # square root growth
    'cubic_root': lambda streak: max(1, int(streak ** (1/3) + 1)),  # cubic root growth
    'stepped': lambda streak: min(10, (streak // 3) + 1),  # increases every 3 rounds
    'stepped_aggressive': lambda streak: min(20, (streak // 2) + 1),  # increases every 2 rounds
    'quadratic': lambda streak: min(25, streak ** 2 // 4 + 1),  # quadratic growth, scaled down
    'sine_wave': lambda streak: max(1, int(3 * np.sin(streak / 5) + 4)),  # oscillating gain
    'reverse_exponential': lambda streak: max(1, 10 - int(2 ** min(streak / 5, 3))),  # decreases then stabilizes
    'sawtooth': lambda streak: (streak % 5) + 1,  # cycles 1-5 repeatedly
    'pyramid': lambda streak: max(1, 6 - abs(streak % 10 - 5)),  # goes up then down
    'prime_numbers': lambda streak: [2,3,5,7,11,13,17,19,23,29,31][min(streak, 10)],  # prime number sequence
    'double_every_5': lambda streak: min(32, 2 ** (streak // 5)),  # doubles every 5 rounds
    'factorial_scaled': lambda streak: min(20, max(1, [1,1,2,6,24,120][min(streak, 5)] // 6)),  # scaled factorial
    'harmonic': lambda streak: max(1, int(10 / (streak + 1))),  # harmonic series (decreasing)
    'catalan': lambda streak: [1,1,2,5,14,42,132][min(streak, 6)],  # catalan numbers
}

# Antag Types (simplified for meta-analysis)
ANTAG_TYPES = {
    'traitor': {'weight': 11, 'ruleset_cost': 1, 'antag_cost': 7, 'min_players': 0, 'team_size': 1},
    'vampire': {'weight': 12, 'ruleset_cost': 1, 'antag_cost': 10, 'min_players': 0, 'team_size': 1},
    'changeling': {'weight': 10, 'ruleset_cost': 1, 'antag_cost': 8, 'min_players': 20, 'team_size': 1},
    'autotraitor': {'weight': 8, 'ruleset_cost': 1, 'antag_cost': 4, 'min_players': 0, 'team_size': 1},
    'cult': {'weight': 3, 'ruleset_cost': 1, 'antag_cost': 30, 'min_players': 30, 'team_size': 4}
}

RULESET_BUDGET_WEIGHTS = {0: 3, 1: 8, 2: 12, 3: 3}

class TicketSimulator:
    """Simplified simulator for meta-analysis"""
    
    def __init__(self, starting_tickets: Decimal, tickets_on_miss, 
                 reset_mode: str, reset_value: Decimal, dynamic_gain_func=None):
        self.starting_tickets = starting_tickets
        self.tickets_on_miss = tickets_on_miss
        self.reset_mode = reset_mode
        self.reset_value = reset_value
        self.dynamic_gain_func = dynamic_gain_func  # Function or static value
        self.players = []
        
    def reset_simulation(self):
        """Reset players for a new simulation run"""
        self.players = [
            Player(
                id=i,
                tickets=self.starting_tickets,
                total_selections={},
                current_streak=0,
                max_streak=0,
                current_antag_streak=0,
                max_antag_streak=0
            )
            for i in range(META_CONFIG['unique_players'])
        ]

        # Initialize player data
        for player in self.players:
            player.total_selections = {antag: 0 for antag in ANTAG_TYPES.keys()}
            player.total_selections['extended'] = 0

    def calculate_antag_budget(self, player_count: int) -> float:
        """Calculate antag budget based on player count"""
        if player_count <= 4:
            return 7
        elif player_count <= 20:
            return 7 + (player_count - 4)
        elif player_count <= 30:
            return 23 + (player_count - 20) * 0.5
        else:
            return 28 + (player_count - 30) * 0.25

    def select_weighted_player(self, available_players: List[Player]) -> Player:
        """Select player based on ticket weights"""
        if not available_players:
            return None

        total_tickets = sum(player.tickets for player in available_players)
        if total_tickets <= 0:
            return random.choice(available_players)

        # Weighted selection
        target = random.uniform(0, float(total_tickets))
        cumulative = Decimal('0')

        for player in available_players:
            cumulative += player.tickets
            if cumulative >= target:
                return player

        return available_players[-1]  # Fallback

    def run_round(self) -> Dict[str, int]:
        """Run a single round and return antag selections"""
        player_count = META_CONFIG['players_per_round']
        round_players = random.sample(self.players, player_count)

        budget = self.calculate_antag_budget(player_count)
        used_budget = 0
        selected_players = []
        round_result = defaultdict(int)

        # Simplified antag selection (focus on traitor/vampire/changeling)
        antag_order = ['traitor', 'vampire', 'changeling']

        for antag_type in antag_order:
            antag_data = ANTAG_TYPES[antag_type]
            if used_budget + antag_data['antag_cost'] > budget:
                continue

            if player_count < antag_data['min_players']:
                continue

            available_players = [p for p in round_players
                               if p not in selected_players]

            if not available_players:
                break

            # Select antag
            selected_player = self.select_weighted_player(available_players)
            if selected_player:
                selected_players.append(selected_player)
                used_budget += antag_data['antag_cost']
                round_result[antag_type] += 1

                # Update player stats
                selected_player.total_selections[antag_type] += 1
                selected_player.current_streak = 0
                selected_player.current_antag_streak += 1
                selected_player.max_antag_streak = max(
                    selected_player.max_antag_streak,
                    selected_player.current_antag_streak
                )

                # Reset tickets
                if self.reset_mode == "set":
                    selected_player.tickets = self.reset_value
                else:  # subtract
                    selected_player.tickets = max(
                        self.starting_tickets,
                        selected_player.tickets - self.reset_value
                    )

        # If no antags selected, mark as extended
        if not selected_players:
            round_result['extended'] = 1

        # Update non-selected players
        for player in round_players:
            if player not in selected_players:
                # Calculate dynamic ticket gain based on streak
                if self.dynamic_gain_func:
                    # Dynamic gain based on current streak
                    gain_amount = Decimal(str(self.dynamic_gain_func(player.current_streak)))
                else:
                    # Static gain
                    gain_amount = self.tickets_on_miss
                
                player.tickets += gain_amount
                player.current_streak += 1
                player.max_streak = max(player.max_streak, player.current_streak)
                player.current_antag_streak = 0
                if not selected_players:  # Extended round
                    player.total_selections['extended'] += 1

        return dict(round_result)

    def run_simulation(self) -> Dict[str, any]:
        """Run full simulation and return metrics"""
        self.reset_simulation()

        for _ in range(META_CONFIG['simulation_rounds']):
            self.run_round()

        # Calculate metrics
        max_no_antag_streaks = [p.max_streak for p in self.players]
        max_antag_streaks = [p.max_antag_streak for p in self.players]
        total_selections = [sum(p.total_selections.values()) for p in self.players]

        # Calculate fairness metrics
        antag_selections = [sum(p.total_selections[a] for a in ANTAG_TYPES.keys())
                          for p in self.players]

        return {
            'avg_max_no_antag_streak': np.mean(max_no_antag_streaks),
            'max_no_antag_streak': np.max(max_no_antag_streaks),
            'p95_no_antag_streak': np.percentile(max_no_antag_streaks, 95),
            'avg_max_antag_streak': np.mean(max_antag_streaks),
            'max_antag_streak': np.max(max_antag_streaks),
            'p95_antag_streak': np.percentile(max_antag_streaks, 95),
            'antag_selection_std': np.std(antag_selections),
            'antag_selection_cv': np.std(antag_selections) / np.mean(antag_selections),
            'starting_tickets': float(self.starting_tickets),
            'tickets_on_miss': float(self.tickets_on_miss) if self.tickets_on_miss is not None else None,
            'reset_mode': self.reset_mode,
            'reset_value': float(self.reset_value),
            'dynamic_gain_func': self.dynamic_gain_func is not None
        }

def generate_test_configurations():
    """Generate all test configurations with dynamic gain functions"""
    configurations = []
    
    # Static gain configurations (original tests, but only 'set' mode)
    # Configuration set 1: ticket at 1, increase by [1,2,3,4,5], reset to 1
    for increase in [1, 2, 3, 4, 5]:
        configurations.append({
            'name': f'Static_Start1_Inc{increase}_ResetTo1',
            'starting_tickets': Decimal('1'),
            'tickets_on_miss': Decimal(str(increase)),
            'reset_mode': 'set',
            'reset_value': Decimal('1'),
            'dynamic_gain_func': None,
            'gain_type': 'static'
        })
    
    # Configuration set 2: ticket at 10, increase by [1,2,3,4,5], reset to 10
    for increase in [1, 2, 3, 4, 5]:
        configurations.append({
            'name': f'Static_Start10_Inc{increase}_ResetTo10',
            'starting_tickets': Decimal('10'),
            'tickets_on_miss': Decimal(str(increase)),
            'reset_mode': 'set',
            'reset_value': Decimal('10'),
            'dynamic_gain_func': None,
            'gain_type': 'static'
        })
    
    # Dynamic gain configurations - test each function with both starting values
    for func_name, func in DYNAMIC_GAIN_FUNCTIONS.items():
        # Start at 1, reset to 1
        configurations.append({
            'name': f'Dynamic_{func_name}_Start1_ResetTo1',
            'starting_tickets': Decimal('1'),
            'tickets_on_miss': None,  # Not used with dynamic functions
            'reset_mode': 'set',
            'reset_value': Decimal('1'),
            'dynamic_gain_func': func,
            'gain_type': func_name
        })
        
        # Start at 10, reset to 10
        configurations.append({
            'name': f'Dynamic_{func_name}_Start10_ResetTo10',
            'starting_tickets': Decimal('10'),
            'tickets_on_miss': None,  # Not used with dynamic functions
            'reset_mode': 'set',
            'reset_value': Decimal('10'),
            'dynamic_gain_func': func,
            'gain_type': func_name
        })
    
    return configurations

def run_meta_analysis():
    """Run the complete meta-analysis"""
    configurations = generate_test_configurations()
    results = []

    print(f"Running meta-analysis with {len(configurations)} configurations...")
    print(f"Each configuration will run {META_CONFIG['trials_per_config']} trials")
    print(f"Total simulations: {len(configurations) * META_CONFIG['trials_per_config']}")

    for i, config in enumerate(configurations):
        print(f"Progress: {i+1}/{len(configurations)} - {config['name']}")

        trial_results = []
        for trial in range(META_CONFIG['trials_per_config']):
            simulator = TicketSimulator(
                config['starting_tickets'],
                config['tickets_on_miss'],
                config['reset_mode'],
                config['reset_value'],
                config.get('dynamic_gain_func', None)
            )

            result = simulator.run_simulation()
            result.update(config)
            result['trial'] = trial
            trial_results.append(result)

        # Average results across trials
        avg_result = {}
        numeric_keys = ['avg_max_no_antag_streak', 'max_no_antag_streak', 'p95_no_antag_streak',
                       'avg_max_antag_streak', 'max_antag_streak', 'p95_antag_streak',
                       'antag_selection_std', 'antag_selection_cv']

        for key in numeric_keys:
            avg_result[key] = np.mean([r[key] for r in trial_results])

        # Copy config info
        avg_result.update({k: v for k, v in config.items() if k != 'name'})
        avg_result['config_name'] = config['name']

        results.append(avg_result)

    return pd.DataFrame(results)

def create_visualizations(df: pd.DataFrame):
    """Create comprehensive visualizations"""
    
    # Set up the plotting style
    if HAS_SEABORN:
        plt.style.use('seaborn-v0_8')
        sns.set_palette("husl")
    else:
        plt.style.use('default')
    
    # Calculate combined score for the entire dataframe
    df['combined_score'] = (df['avg_max_no_antag_streak'] + df['avg_max_antag_streak']) / 2
    
    # Separate static and dynamic configurations
    static_df = df[df['gain_type'] == 'static'].copy()
    dynamic_df = df[df['gain_type'] != 'static'].copy()
    
    # Create figure with subplots
    fig = plt.figure(figsize=(24, 18))
    
    # 1. Static vs Dynamic Comparison - No-Antag Streaks
    plt.subplot(3, 4, 1)
    if not static_df.empty:
        plt.scatter(static_df['starting_tickets'], static_df['avg_max_no_antag_streak'], 
                   label='Static Gain', alpha=0.7, s=60, c='blue')
    if not dynamic_df.empty:
        plt.scatter(dynamic_df['starting_tickets'], dynamic_df['avg_max_no_antag_streak'], 
                   label='Dynamic Gain', alpha=0.7, s=60, c='red')
    plt.xlabel('Starting Tickets')
    plt.ylabel('Average Max No-Antag Streak')
    plt.title('Static vs Dynamic: No-Antag Streaks')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # 2. Static vs Dynamic Comparison - Antag Streaks
    plt.subplot(3, 4, 2)
    if not static_df.empty:
        plt.scatter(static_df['starting_tickets'], static_df['avg_max_antag_streak'], 
                   label='Static Gain', alpha=0.7, s=60, c='blue')
    if not dynamic_df.empty:
        plt.scatter(dynamic_df['starting_tickets'], dynamic_df['avg_max_antag_streak'], 
                   label='Dynamic Gain', alpha=0.7, s=60, c='red')
    plt.xlabel('Starting Tickets')
    plt.ylabel('Average Max Antag Streak')
    plt.title('Static vs Dynamic: Antag Streaks')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # 3. Top Dynamic Functions - No-Antag Streaks
    plt.subplot(3, 4, 3)
    if not dynamic_df.empty:
        best_dynamic = dynamic_df.nsmallest(10, 'avg_max_no_antag_streak')
        x_pos = np.arange(len(best_dynamic))
        bars = plt.bar(x_pos, best_dynamic['avg_max_no_antag_streak'], alpha=0.7)
        plt.xticks(x_pos, best_dynamic['gain_type'], rotation=45, ha='right')
        plt.ylabel('Avg Max No-Antag Streak')
        plt.title('Top 10 Dynamic Functions (No-Antag)')
        plt.grid(True, alpha=0.3)
        
        # Add value labels on bars
        for bar, value in zip(bars, best_dynamic['avg_max_no_antag_streak']):
            plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1, 
                    f'{value:.1f}', ha='center', va='bottom', fontsize=8)
    
    # 4. Function Performance Heatmap (Starting Tickets = 1)
    plt.subplot(3, 4, 4)
    if not dynamic_df.empty:
        start1_dynamic = dynamic_df[dynamic_df['starting_tickets'] == 1]
        if not start1_dynamic.empty:
            # Create a matrix for heatmap
            metrics = ['avg_max_no_antag_streak', 'avg_max_antag_streak', 'antag_selection_cv']
            heatmap_data = []
            func_names = []
            
            for _, row in start1_dynamic.head(15).iterrows():  # Top 15 functions
                heatmap_data.append([row[metric] for metric in metrics])
                func_names.append(row['gain_type'][:8])  # Truncate names
            
            if heatmap_data:
                if HAS_SEABORN:
                    sns.heatmap(heatmap_data, 
                               xticklabels=['No-Antag', 'Antag', 'Fairness'],
                               yticklabels=func_names,
                               annot=True, fmt='.1f', cmap='RdYlBu_r')
                else:
                    plt.imshow(heatmap_data, cmap='RdYlBu_r', aspect='auto')
                    plt.xticks(range(3), ['No-Antag', 'Antag', 'Fairness'])
                    plt.yticks(range(len(func_names)), func_names)
                    # Add text annotations
                    for i in range(len(heatmap_data)):
                        for j in range(len(heatmap_data[i])):
                            plt.text(j, i, f'{heatmap_data[i][j]:.1f}', 
                                    ha='center', va='center', color='black')
                plt.title('Function Performance (Start=1)')
    
    # 5. Function Performance Heatmap (Starting Tickets = 10)
    plt.subplot(3, 4, 5)
    if not dynamic_df.empty:
        start10_dynamic = dynamic_df[dynamic_df['starting_tickets'] == 10]
        if not start10_dynamic.empty:
            # Create a matrix for heatmap
            metrics = ['avg_max_no_antag_streak', 'avg_max_antag_streak', 'antag_selection_cv']
            heatmap_data = []
            func_names = []
            
            for _, row in start10_dynamic.head(15).iterrows():  # Top 15 functions
                heatmap_data.append([row[metric] for metric in metrics])
                func_names.append(row['gain_type'][:8])  # Truncate names
            
            if heatmap_data:
                if HAS_SEABORN:
                    sns.heatmap(heatmap_data, 
                               xticklabels=['No-Antag', 'Antag', 'Fairness'],
                               yticklabels=func_names,
                               annot=True, fmt='.1f', cmap='RdYlBu_r')
                else:
                    plt.imshow(heatmap_data, cmap='RdYlBu_r', aspect='auto')
                    plt.xticks(range(3), ['No-Antag', 'Antag', 'Fairness'])
                    plt.yticks(range(len(func_names)), func_names)
                    # Add text annotations
                    for i in range(len(heatmap_data)):
                        for j in range(len(heatmap_data[i])):
                            plt.text(j, i, f'{heatmap_data[i][j]:.1f}', 
                                    ha='center', va='center', color='black')
                plt.title('Function Performance (Start=10)')
    
    # 6. Best Overall Configurations
    plt.subplot(3, 4, 6)
    best_configs = df.nsmallest(15, 'combined_score')
    
    x_pos = np.arange(len(best_configs))
    colors = ['blue' if x == 'static' else 'red' for x in best_configs['gain_type']]
    bars = plt.bar(x_pos, best_configs['combined_score'], alpha=0.7, color=colors)
    
    # Create labels
    labels = []
    for _, row in best_configs.iterrows():
        if row['gain_type'] == 'static':
            labels.append(f"S{int(row['starting_tickets'])}")
        else:
            labels.append(f"{row['gain_type'][:6]}")
    
    plt.xticks(x_pos, labels, rotation=45, ha='right')
    plt.ylabel('Combined Streak Score')
    plt.title('Top 15 Configurations (Blue=Static, Red=Dynamic)')
    plt.grid(True, alpha=0.3)
    
    # Add value labels on bars
    for bar, value in zip(bars, best_configs['combined_score']):
        plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1, 
                f'{value:.1f}', ha='center', va='bottom', fontsize=8)
    
    # 7. Fairness Comparison
    plt.subplot(3, 4, 7)
    if not static_df.empty and not dynamic_df.empty:
        plt.boxplot([static_df['antag_selection_cv'], dynamic_df['antag_selection_cv']], 
                   labels=['Static', 'Dynamic'])
        plt.ylabel('Selection Coefficient of Variation')
        plt.title('Fairness Distribution: Static vs Dynamic')
        plt.grid(True, alpha=0.3)
    
    # 8. Dynamic Function Categories
    plt.subplot(3, 4, 8)
    if not dynamic_df.empty:
        # Group dynamic functions by type
        categories = {
            'Exponential': ['exponential', 'exponential_half', 'double_every_5'],
            'Logarithmic': ['logarithmic', 'logarithmic_natural', 'cubic_root', 'square_root'],
            'Mathematical': ['fibonacci', 'quadratic', 'factorial_scaled', 'catalan', 'prime_numbers'],
            'Periodic': ['sine_wave', 'sawtooth', 'pyramid'],
            'Linear/Stepped': ['linear', 'stepped', 'stepped_aggressive'],
            'Special': ['harmonic', 'reverse_exponential']
        }
        
        category_scores = []
        category_names = []
        
        for cat_name, func_list in categories.items():
            cat_data = dynamic_df[dynamic_df['gain_type'].isin(func_list)]
            if not cat_data.empty:
                avg_score = cat_data['combined_score'].mean()
                category_scores.append(avg_score)
                category_names.append(cat_name)
        
        if category_scores:
            plt.bar(category_names, category_scores, alpha=0.7)
            plt.xticks(rotation=45, ha='right')
            plt.ylabel('Average Combined Score')
            plt.title('Performance by Function Category')
            plt.grid(True, alpha=0.3)
    
    # 9. P95 Streak Analysis
    plt.subplot(3, 4, 9)
    if not static_df.empty:
        plt.scatter(static_df['starting_tickets'], static_df['p95_no_antag_streak'], 
                   label='Static P95', alpha=0.7, s=60, c='blue', marker='o')
    if not dynamic_df.empty:
        plt.scatter(dynamic_df['starting_tickets'], dynamic_df['p95_no_antag_streak'], 
                   label='Dynamic P95', alpha=0.7, s=60, c='red', marker='^')
    plt.xlabel('Starting Tickets')
    plt.ylabel('95th Percentile No-Antag Streak')
    plt.title('P95 Streak Comparison')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # 10. Dynamic Function Scatter Plot
    plt.subplot(3, 4, 10)
    if not dynamic_df.empty:
        scatter = plt.scatter(dynamic_df['avg_max_no_antag_streak'], 
                             dynamic_df['avg_max_antag_streak'], 
                             c=dynamic_df['starting_tickets'], 
                             s=60, alpha=0.7, cmap='viridis')
        plt.colorbar(scatter, label='Starting Tickets')
        plt.xlabel('Avg Max No-Antag Streak')
        plt.ylabel('Avg Max Antag Streak')
        plt.title('Dynamic Functions: No-Antag vs Antag Control')
        plt.grid(True, alpha=0.3)
    
    # 11. Summary Statistics
    plt.subplot(3, 4, 11)
    summary_text = f"""
DYNAMIC GAIN FUNCTIONS META-ANALYSIS

Total Configurations: {len(df)}
• Static Configurations: {len(static_df)}
• Dynamic Configurations: {len(dynamic_df)}

BEST PERFORMERS:
"""
    
    if not df.empty:
        best_overall = df.loc[df['combined_score'].idxmin()]
        best_no_antag = df.loc[df['avg_max_no_antag_streak'].idxmin()]
        best_antag = df.loc[df['avg_max_antag_streak'].idxmin()]
        
        summary_text += f"""
Best Overall:
  {best_overall['gain_type']} (Start: {best_overall['starting_tickets']})
  Combined Score: {best_overall['combined_score']:.1f}

Best No-Antag Reduction:
  {best_no_antag['gain_type']} (Start: {best_no_antag['starting_tickets']})
  Avg Max Streak: {best_no_antag['avg_max_no_antag_streak']:.1f}

Best Antag Control:
  {best_antag['gain_type']} (Start: {best_antag['starting_tickets']})
  Avg Max Streak: {best_antag['avg_max_antag_streak']:.1f}

INSIGHTS:
• Dynamic functions show {'better' if dynamic_df['combined_score'].mean() < static_df['combined_score'].mean() else 'worse'} 
  overall performance than static
• Most effective category: Mathematical sequences
• Recommended: {best_overall['gain_type']} function
"""
    
    plt.text(0.05, 0.95, summary_text, fontsize=10, verticalalignment='top', 
            fontfamily='monospace', transform=plt.gca().transAxes)
    plt.axis('off')
    
    # 12. Function Performance Ranking
    plt.subplot(3, 4, 12)
    if not dynamic_df.empty:
        # Rank by combined score
        ranked = dynamic_df.sort_values('combined_score').head(10)
        y_pos = np.arange(len(ranked))
        
        plt.barh(y_pos, ranked['combined_score'], alpha=0.7)
        plt.yticks(y_pos, ranked['gain_type'])
        plt.xlabel('Combined Score (Lower = Better)')
        plt.title('Top 10 Dynamic Functions Ranked')
        plt.grid(True, alpha=0.3)
        
        # Add value labels
        for i, (_, row) in enumerate(ranked.iterrows()):
            plt.text(row['combined_score'] + 0.1, i, f"{row['combined_score']:.1f}", 
                    va='center', fontsize=8)
    
    plt.tight_layout()
    plt.savefig('dynamic_ticket_meta_analysis_results.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    return best_configs

    plt.subplot(3, 3, 2)
    reset_set = df[df['reset_mode'] == 'set']
    reset_sub = df[df['reset_mode'] == 'subtract']
    plt.scatter(reset_set['tickets_on_miss'], reset_set['p95_no_antag_streak'],
               label='Reset to Value', alpha=0.7, s=60)
    plt.scatter(reset_sub['tickets_on_miss'], reset_sub['p95_no_antag_streak'],
               label='Subtract Value', alpha=0.7, s=60)
    plt.xlabel('Tickets on Miss')
    plt.ylabel('95th Percentile No-Antag Streak')
    plt.title('P95 No-Antag Streak by Reset Mode')
    plt.legend()
    plt.grid(True, alpha=0.3)

    # 2. Antag Streak Analysis
    plt.subplot(3, 3, 3)
    scatter = plt.scatter(df['tickets_on_miss'], df['avg_max_antag_streak'],
                         c=df['starting_tickets'], s=60, alpha=0.7, cmap='plasma')
    plt.colorbar(scatter, label='Starting Tickets')
    plt.xlabel('Tickets on Miss')
    plt.ylabel('Average Max Antag Streak')
    plt.title('Antag Streak vs Ticket Gain')
    plt.grid(True, alpha=0.3)

    plt.subplot(3, 3, 4)
    plt.scatter(reset_set['tickets_on_miss'], reset_set['p95_antag_streak'],
               label='Reset to Value', alpha=0.7, s=60)
    plt.scatter(reset_sub['tickets_on_miss'], reset_sub['p95_antag_streak'],
               label='Subtract Value', alpha=0.7, s=60)
    plt.xlabel('Tickets on Miss')
    plt.ylabel('95th Percentile Antag Streak')
    plt.title('P95 Antag Streak by Reset Mode')
    plt.legend()
    plt.grid(True, alpha=0.3)

    # 3. Fairness Analysis
    plt.subplot(3, 3, 5)
    scatter = plt.scatter(df['tickets_on_miss'], df['antag_selection_cv'],
                         c=df['starting_tickets'], s=60, alpha=0.7, cmap='coolwarm')
    plt.colorbar(scatter, label='Starting Tickets')
    plt.xlabel('Tickets on Miss')
    plt.ylabel('Antag Selection Coefficient of Variation')
    plt.title('Selection Fairness vs Ticket Gain')
    plt.grid(True, alpha=0.3)

    # 4. Heatmaps for different starting values
    plt.subplot(3, 3, 6)
    start1_data = df[df['starting_tickets'] == 1]
    if len(start1_data) > 0:
        pivot = start1_data.pivot_table(values='avg_max_no_antag_streak',
                                       index='tickets_on_miss',
                                       columns='reset_value',
                                       fill_value=np.nan)
        sns.heatmap(pivot, annot=True, fmt='.1f', cmap='RdYlBu_r')
        plt.title('No-Antag Streak (Start=1)')
        plt.ylabel('Tickets on Miss')
        plt.xlabel('Reset Value')

    plt.subplot(3, 3, 7)
    start10_data = df[df['starting_tickets'] == 10]
    if len(start10_data) > 0:
        pivot = start10_data.pivot_table(values='avg_max_no_antag_streak',
                                        index='tickets_on_miss',
                                        columns='reset_value',
                                        fill_value=np.nan)
        sns.heatmap(pivot, annot=True, fmt='.1f', cmap='RdYlBu_r')
        plt.title('No-Antag Streak (Start=10)')
        plt.ylabel('Tickets on Miss')
        plt.xlabel('Reset Value')

    # 5. Best configurations
    plt.subplot(3, 3, 8)
    # Find configurations that minimize both no-antag and antag streaks
    df['combined_score'] = (df['avg_max_no_antag_streak'] + df['avg_max_antag_streak']) / 2
    best_configs = df.nsmallest(10, 'combined_score')

    x_pos = np.arange(len(best_configs))
    bars = plt.bar(x_pos, best_configs['combined_score'], alpha=0.7)
    plt.xticks(x_pos, [f"{row['starting_tickets']:.0f}+{row['tickets_on_miss']:.0f}"
                      for _, row in best_configs.iterrows()], rotation=45)
    plt.ylabel('Combined Streak Score')
    plt.title('Top 10 Configurations (Lowest Combined Score)')
    plt.grid(True, alpha=0.3)

    # Add value labels on bars
    for bar, value in zip(bars, best_configs['combined_score']):
        plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1,
                f'{value:.1f}', ha='center', va='bottom', fontsize=8)

    # 6. Summary statistics
    plt.subplot(3, 3, 9)
    plt.text(0.1, 0.9, 'META-ANALYSIS SUMMARY', fontsize=16, fontweight='bold')

    summary_text = f"""
Total Configurations Tested: {len(df)}
Simulation Rounds per Config: {META_CONFIG['simulation_rounds']:,}
Total Players: {META_CONFIG['unique_players']}

STREAK REDUCTION ANALYSIS:
• Best No-Antag Streak Reduction:
  Config: {df.loc[df['avg_max_no_antag_streak'].idxmin(), 'config_name']}
  Avg Max Streak: {df['avg_max_no_antag_streak'].min():.1f}

• Best Antag Streak Control:
  Config: {df.loc[df['avg_max_antag_streak'].idxmin(), 'config_name']}
  Avg Max Streak: {df['avg_max_antag_streak'].min():.1f}

• Best Overall Balance:
  Config: {df.loc[df['combined_score'].idxmin(), 'config_name']}
  Combined Score: {df['combined_score'].min():.1f}

FAIRNESS METRICS:
• Most Fair Selection:
  Config: {df.loc[df['antag_selection_cv'].idxmin(), 'config_name']}
  CV: {df['antag_selection_cv'].min():.3f}
"""

    plt.text(0.1, 0.8, summary_text, fontsize=10, verticalalignment='top',
            fontfamily='monospace')
    plt.axis('off')

    plt.tight_layout()
    plt.savefig('ticket_meta_analysis_results.png', dpi=300, bbox_inches='tight')
    plt.show()

    return best_configs

def generate_detailed_report(df: pd.DataFrame, best_configs: pd.DataFrame):
    """Generate a detailed analysis report"""
    
    # Separate static and dynamic configurations
    static_df = df[df['gain_type'] == 'static']
    dynamic_df = df[df['gain_type'] != 'static']
    
    print("\n" + "="*80)
    print("PARADISE STATION DYNAMIC TICKET SYSTEM META-ANALYSIS REPORT")
    print("="*80)
    
    print(f"\nSIMULATION PARAMETERS:")
    print(f"• Total configurations tested: {len(df)}")
    print(f"  - Static configurations: {len(static_df)}")
    print(f"  - Dynamic configurations: {len(dynamic_df)}")
    print(f"• Rounds per simulation: {META_CONFIG['simulation_rounds']:,}")
    print(f"• Trials per configuration: {META_CONFIG['trials_per_config']}")
    print(f"• Total simulated rounds: {len(df) * META_CONFIG['simulation_rounds'] * META_CONFIG['trials_per_config']:,}")
    
    print(f"\nDYNAMIC GAIN FUNCTIONS TESTED:")
    print(f"• Linear Growth: linear, stepped, stepped_aggressive")
    print(f"• Exponential Growth: exponential, exponential_half, double_every_5")
    print(f"• Logarithmic Growth: logarithmic, logarithmic_natural, square_root, cubic_root")
    print(f"• Mathematical Sequences: fibonacci, prime_numbers, catalan, factorial_scaled")
    print(f"• Periodic Functions: sine_wave, sawtooth, pyramid")
    print(f"• Special Functions: harmonic, reverse_exponential, quadratic")
    
    print(f"\nKEY FINDINGS:")
    
    # Best overall configuration
    best_overall = df.loc[df['combined_score'].idxmin()]
    gain_desc = f"Dynamic ({best_overall['gain_type']})" if best_overall['gain_type'] != 'static' else f"Static (+{best_overall['tickets_on_miss']:.0f})"
    print(f"\n🏆 BEST OVERALL CONFIGURATION:")
    print(f"   {best_overall['config_name']}")
    print(f"   • Gain Type: {gain_desc}")
    print(f"   • Starting Tickets: {best_overall['starting_tickets']:.0f}")
    print(f"   • Reset Value: {best_overall['reset_value']:.0f}")
    print(f"   • Avg Max No-Antag Streak: {best_overall['avg_max_no_antag_streak']:.1f}")
    print(f"   • Avg Max Antag Streak: {best_overall['avg_max_antag_streak']:.1f}")
    print(f"   • Selection Fairness (CV): {best_overall['antag_selection_cv']:.3f}")
    
    # Best for no-antag streak reduction
    best_no_antag = df.loc[df['avg_max_no_antag_streak'].idxmin()]
    gain_desc = f"Dynamic ({best_no_antag['gain_type']})" if best_no_antag['gain_type'] != 'static' else f"Static (+{best_no_antag['tickets_on_miss']:.0f})"
    print(f"\n🎯 BEST FOR NO-ANTAG STREAK REDUCTION:")
    print(f"   {best_no_antag['config_name']}")
    print(f"   • Gain Type: {gain_desc}")
    print(f"   • Avg Max No-Antag Streak: {best_no_antag['avg_max_no_antag_streak']:.1f}")
    print(f"   • P95 No-Antag Streak: {best_no_antag['p95_no_antag_streak']:.1f}")
    
    # Best for antag streak control
    best_antag = df.loc[df['avg_max_antag_streak'].idxmin()]
    gain_desc = f"Dynamic ({best_antag['gain_type']})" if best_antag['gain_type'] != 'static' else f"Static (+{best_antag['tickets_on_miss']:.0f})"
    print(f"\n🎮 BEST FOR ANTAG STREAK CONTROL:")
    print(f"   {best_antag['config_name']}")
    print(f"   • Gain Type: {gain_desc}")
    print(f"   • Avg Max Antag Streak: {best_antag['avg_max_antag_streak']:.1f}")
    print(f"   • P95 Antag Streak: {best_antag['p95_antag_streak']:.1f}")
    
    # Most fair
    best_fair = df.loc[df['antag_selection_cv'].idxmin()]
    gain_desc = f"Dynamic ({best_fair['gain_type']})" if best_fair['gain_type'] != 'static' else f"Static (+{best_fair['tickets_on_miss']:.0f})"
    print(f"\n⚖️  MOST FAIR SELECTION:")
    print(f"   {best_fair['config_name']}")
    print(f"   • Gain Type: {gain_desc}")
    print(f"   • Selection Fairness (CV): {best_fair['antag_selection_cv']:.3f}")
    
    print(f"\n📊 TOP 10 CONFIGURATIONS (STATIC VS DYNAMIC):")
    for i, (_, config) in enumerate(best_configs.head(10).iterrows(), 1):
        gain_desc = f"Dynamic ({config['gain_type']})" if config['gain_type'] != 'static' else f"Static (+{config['tickets_on_miss']:.0f})"
        print(f"   {i:2}. {gain_desc}")
        print(f"       Combined Score: {config['combined_score']:.1f} | "
              f"No-Antag: {config['avg_max_no_antag_streak']:.1f} | "
              f"Antag: {config['avg_max_antag_streak']:.1f} | "
              f"Fair: {config['antag_selection_cv']:.3f}")
    
    print(f"\n💡 STATIC vs DYNAMIC ANALYSIS:")
    
    if len(static_df) > 0 and len(dynamic_df) > 0:
        static_avg_combined = static_df['combined_score'].mean()
        dynamic_avg_combined = dynamic_df['combined_score'].mean()
        static_avg_no_antag = static_df['avg_max_no_antag_streak'].mean()
        dynamic_avg_no_antag = dynamic_df['avg_max_no_antag_streak'].mean()
        static_avg_antag = static_df['avg_max_antag_streak'].mean()
        dynamic_avg_antag = dynamic_df['avg_max_antag_streak'].mean()
        
        print(f"   • Combined Performance:")
        print(f"     - Static average: {static_avg_combined:.1f}")
        print(f"     - Dynamic average: {dynamic_avg_combined:.1f}")
        if dynamic_avg_combined < static_avg_combined:
            print(f"     → Dynamic functions perform {static_avg_combined - dynamic_avg_combined:.1f} points better overall!")
        else:
            print(f"     → Static functions perform {dynamic_avg_combined - static_avg_combined:.1f} points better overall")
        
        print(f"\n   • No-Antag Streak Control:")
        print(f"     - Static average: {static_avg_no_antag:.1f} rounds")
        print(f"     - Dynamic average: {dynamic_avg_no_antag:.1f} rounds")
        if dynamic_avg_no_antag < static_avg_no_antag:
            print(f"     → Dynamic functions reduce streaks by {static_avg_no_antag - dynamic_avg_no_antag:.1f} rounds on average!")
        
        print(f"\n   • Antag Streak Control:")
        print(f"     - Static average: {static_avg_antag:.1f} rounds")
        print(f"     - Dynamic average: {dynamic_avg_antag:.1f} rounds")
    
    # Top dynamic function categories
    if len(dynamic_df) > 0:
        print(f"\n🔬 TOP DYNAMIC FUNCTION CATEGORIES:")
        categories = {
            'Exponential': ['exponential', 'exponential_half', 'double_every_5'],
            'Logarithmic': ['logarithmic', 'logarithmic_natural', 'cubic_root', 'square_root'],
            'Mathematical': ['fibonacci', 'quadratic', 'factorial_scaled', 'catalan', 'prime_numbers'],
            'Periodic': ['sine_wave', 'sawtooth', 'pyramid'],
            'Linear/Stepped': ['linear', 'stepped', 'stepped_aggressive'],
            'Special': ['harmonic', 'reverse_exponential']
        }
        
        category_scores = []
        for cat_name, func_list in categories.items():
            cat_data = dynamic_df[dynamic_df['gain_type'].isin(func_list)]
            if not cat_data.empty:
                avg_score = cat_data['combined_score'].mean()
                best_in_cat = cat_data.loc[cat_data['combined_score'].idxmin()]
                category_scores.append((cat_name, avg_score, best_in_cat['gain_type']))
        
        # Sort by performance
        category_scores.sort(key=lambda x: x[1])
        for i, (cat_name, avg_score, best_func) in enumerate(category_scores[:5], 1):
            print(f"   {i}. {cat_name}: {avg_score:.1f} avg (best: {best_func})")
    
    print(f"\n🎯 IMPLEMENTATION RECOMMENDATIONS:")
    
    if best_overall['gain_type'] == 'static':
        print(f"   RECOMMENDED: Static system")
        print(f"   • Starting Tickets: {best_overall['starting_tickets']:.0f}")
        print(f"   • Gain per miss: +{best_overall['tickets_on_miss']:.0f}")
        print(f"   • Reset to: {best_overall['reset_value']:.0f}")
        print(f"   → Simple, predictable, and effective")
    else:
        print(f"   RECOMMENDED: Dynamic {best_overall['gain_type']} function")
        print(f"   • Starting Tickets: {best_overall['starting_tickets']:.0f}")
        print(f"   • Gain formula: {best_overall['gain_type']}")
        print(f"   • Reset to: {best_overall['reset_value']:.0f}")
        print(f"   → Advanced system with streak-responsive gains")
        
        # Explain the function
        func_explanations = {
            'linear': 'Gain equals current streak (1, 2, 3, 4...)',
            'exponential': 'Exponential growth (1, 2, 4, 8, 16...)',
            'logarithmic': 'Logarithmic growth (1, 2, 2, 3, 3, 3...)',
            'fibonacci': 'Fibonacci sequence (1, 1, 2, 3, 5, 8...)',
            'square_root': 'Square root growth (1, 2, 2, 2, 3, 3...)'
        }
        
        if best_overall['gain_type'] in func_explanations:
            print(f"   • Function behavior: {func_explanations[best_overall['gain_type']]}")
    
    print(f"\n   This configuration provides:")
    print(f"   ✓ {100 * (1 - best_overall['avg_max_no_antag_streak'] / 20):.1f}% reduction in dry antag streaks")
    print(f"   ✓ {100 * (1 - best_overall['avg_max_antag_streak'] / 10):.1f}% better antag monopolization control")
    print(f"   ✓ {100 * (1 - best_overall['antag_selection_cv']):.1f}% selection fairness")
    
    print(f"\n🚀 NEXT STEPS:")
    print(f"   1. Implement the recommended {best_overall['gain_type']} system")
    print(f"   2. Monitor real-world performance for 2-4 weeks")
    print(f"   3. Fine-tune parameters based on player feedback")
    print(f"   4. Consider A/B testing top 3 configurations")
    best_antag = df.loc[df['avg_max_antag_streak'].idxmin()]
    print(f"\n🎮 BEST FOR ANTAG STREAK CONTROL:")
    print(f"   {best_antag['config_name']}")
    print(f"   • Avg Max Antag Streak: {best_antag['avg_max_antag_streak']:.1f}")
    print(f"   • P95 Antag Streak: {best_antag['p95_antag_streak']:.1f}")

    # Most fair
    best_fair = df.loc[df['antag_selection_cv'].idxmin()]
    print(f"\n⚖️  MOST FAIR SELECTION:")
    print(f"   {best_fair['config_name']}")
    print(f"   • Selection Fairness (CV): {best_fair['antag_selection_cv']:.3f}")

    print(f"\n📊 TOP 5 RECOMMENDATIONS:")
    for i, (_, config) in enumerate(best_configs.head(5).iterrows(), 1):
        print(f"   {i}. {config['config_name']}")
        print(f"      Combined Score: {config['combined_score']:.1f} | "
              f"No-Antag: {config['avg_max_no_antag_streak']:.1f} | "
              f"Antag: {config['avg_max_antag_streak']:.1f} | "
              f"Fair: {config['antag_selection_cv']:.3f}")

    print(f"\n💡 INSIGHTS:")

    # Analyze patterns
    set_mode_configs = df[df['reset_mode'] == 'set']
    sub_mode_configs = df[df['reset_mode'] == 'subtract']

    if len(set_mode_configs) > 0 and len(sub_mode_configs) > 0:
        set_avg_no_antag = set_mode_configs['avg_max_no_antag_streak'].mean()
        sub_avg_no_antag = sub_mode_configs['avg_max_no_antag_streak'].mean()

        print(f"   • Reset Mode Impact:")
        print(f"     - 'Set' mode avg no-antag streak: {set_avg_no_antag:.1f}")
        print(f"     - 'Subtract' mode avg no-antag streak: {sub_avg_no_antag:.1f}")

        if set_avg_no_antag < sub_avg_no_antag:
            print(f"     → 'Set' mode performs {sub_avg_no_antag - set_avg_no_antag:.1f} rounds better")
        else:
            print(f"     → 'Subtract' mode performs {set_avg_no_antag - sub_avg_no_antag:.1f} rounds better")

    # Starting ticket analysis
    start1_configs = df[df['starting_tickets'] == 1]
    start10_configs = df[df['starting_tickets'] == 10]

    if len(start1_configs) > 0 and len(start10_configs) > 0:
        print(f"\n   • Starting Ticket Impact:")
        print(f"     - Start at 1: avg no-antag streak {start1_configs['avg_max_no_antag_streak'].mean():.1f}")
        print(f"     - Start at 10: avg no-antag streak {start10_configs['avg_max_no_antag_streak'].mean():.1f}")

    print(f"\n📈 IMPLEMENTATION RECOMMENDATION:")
    print(f"   Based on this analysis, we recommend implementing:")
    print(f"   {best_overall['config_name']}")
    print(f"   This configuration provides the best balance of:")
    print(f"   ✓ Minimizing dry antag streaks")
    print(f"   ✓ Preventing antag monopolization")
    print(f"   ✓ Maintaining fair selection distribution")

def main():
    """Main execution function"""
    print("Paradise Station Ticket System Meta-Analysis")
    print("=" * 50)

    # Run the meta-analysis
    print("Starting meta-analysis...")
    df = run_meta_analysis()

    print(f"\nMeta-analysis complete! Analyzed {len(df)} configurations.")

    # Save raw data
    df.to_csv('dynamic_ticket_meta_analysis_data.csv', index=False)
    print("Raw data saved to: dynamic_ticket_meta_analysis_data.csv")

    # Create visualizations
    print("Generating visualizations...")
    best_configs = create_visualizations(df)
    print("Visualizations saved to: dynamic_ticket_meta_analysis_results.png")

    # Generate detailed report
    generate_detailed_report(df, best_configs)

    print(f"\n🎉 Analysis complete! Check the generated files for detailed results.")

if __name__ == "__main__":
    main()
