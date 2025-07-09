""
Debug settings that print the database configuration.
"""
from .settings import *

# Print database configuration
print("\n=== Database Configuration ===")
print(f"DATABASES: {DATABASES}")
print(f"DATABASE_ROUTERS: {DATABASE_ROUTERS}")
print("===========================\n")
