#!/usr/bin/env python3
"""
Sample data engineering script for the playground.
This demonstrates connecting to PostgreSQL from Python.
"""

import os
import psycopg2
import json
from datetime import datetime, timedelta
import random

# Database connection parameters
DB_CONFIG = {
    'host': 'postgres',  # Use service name when running inside Docker
    'database': 'playground',
    'user': 'deuser',
    'password': 'depassword',
    'port': 5432
}

def connect_to_database():
    """Establish connection to PostgreSQL database."""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        print("✓ Successfully connected to PostgreSQL")
        return conn
    except Exception as e:
        print(f"✗ Error connecting to database: {e}")
        return None

def generate_sample_events(conn, num_events=100):
    """Generate and insert sample events for testing."""
    cursor = conn.cursor()
    
    # Get existing user IDs
    cursor.execute("SELECT id FROM data_eng.users")
    user_ids = [row[0] for row in cursor.fetchall()]
    
    if not user_ids:
        print("No users found. Please check the database initialization.")
        return
    
    event_types = ['login', 'logout', 'page_view', 'purchase', 'search', 'download']
    browsers = ['Chrome', 'Firefox', 'Safari', 'Edge']
    pages = ['/dashboard', '/profile', '/products', '/checkout', '/help']
    
    events = []
    for _ in range(num_events):
        user_id = random.choice(user_ids)
        event_type = random.choice(event_types)
        
        # Generate appropriate event data based on type
        if event_type == 'login':
            event_data = {
                'ip': f"192.168.1.{random.randint(100, 200)}",
                'browser': random.choice(browsers)
            }
        elif event_type == 'page_view':
            event_data = {
                'page': random.choice(pages),
                'duration': random.randint(10, 300)
            }
        elif event_type == 'purchase':
            event_data = {
                'item': f"product_{random.randint(1, 100)}",
                'amount': round(random.uniform(5.99, 199.99), 2)
            }
        else:
            event_data = {
                'action': event_type,
                'timestamp': datetime.now().isoformat()
            }
        
        # Random timestamp within the last 30 days
        created_at = datetime.now() - timedelta(
            days=random.randint(0, 30),
            hours=random.randint(0, 23),
            minutes=random.randint(0, 59)
        )
        
        events.append((user_id, event_type, json.dumps(event_data), created_at))
    
    # Insert events
    cursor.executemany(
        "INSERT INTO data_eng.events (user_id, event_type, event_data, created_at) VALUES (%s, %s, %s, %s)",
        events
    )
    
    conn.commit()
    print(f"✓ Generated and inserted {num_events} sample events")

def analyze_user_behavior(conn):
    """Perform sample data analysis."""
    cursor = conn.cursor()
    
    print("\n=== User Behavior Analysis ===")
    
    # Most active users
    cursor.execute("""
        SELECT u.username, COUNT(e.id) as event_count
        FROM data_eng.users u
        LEFT JOIN data_eng.events e ON u.id = e.user_id
        GROUP BY u.id, u.username
        ORDER BY event_count DESC
        LIMIT 5
    """)
    
    print("\nTop 5 Most Active Users:")
    for username, count in cursor.fetchall():
        print(f"  {username}: {count} events")
    
    # Event type distribution
    cursor.execute("""
        SELECT event_type, COUNT(*) as count
        FROM data_eng.events
        GROUP BY event_type
        ORDER BY count DESC
    """)
    
    print("\nEvent Type Distribution:")
    for event_type, count in cursor.fetchall():
        print(f"  {event_type}: {count}")
    
    # Daily activity (last 7 days)
    cursor.execute("""
        SELECT DATE(created_at) as date, COUNT(*) as events
        FROM data_eng.events
        WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
        GROUP BY DATE(created_at)
        ORDER BY date DESC
    """)
    
    print("\nDaily Activity (Last 7 Days):")
    for date, events in cursor.fetchall():
        print(f"  {date}: {events} events")

def main():
    """Main function to demonstrate the data engineering playground."""
    print("=== Data Engineering Playground Demo ===\n")
    
    # Connect to database
    conn = connect_to_database()
    if not conn:
        return
    
    try:
        # Generate sample data
        print("\nGenerating sample events...")
        generate_sample_events(conn, 50)
        
        # Perform analysis
        analyze_user_behavior(conn)
        
        print("\n=== Demo completed successfully! ===")
        print("\nTry connecting to the database directly:")
        print("  psql -h postgres -U deuser -d playground")
        print("\nOr use the playground script:")
        print("  ./playground.sh psql")
        
    except Exception as e:
        print(f"Error during demo: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
