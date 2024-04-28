import pandas as pd
dis=pd.read_csv('/tmp/discharge.csv')
dis_det=pd.read_csv('/tmp/discharge_detail.csv')

d = pd.merge(dis, dis_det, on='note_id', how='inner')
d= d.drop(columns=['subject_id_x'])
d= d.rename(columns={"subject_id_y": "subject_id"})

from urllib.parse import quote_plus
from sqlalchemy import create_engine

# Original password with special characters
raw_password = "password"

# URL-encode the password
encoded_password = quote_plus(raw_password)

# Now, build your connection string using the encoded password
username = 'root'
host = 'localhost'
database_name = 'openemr'
connection_string = f"mysql+pymysql://{username}:{encoded_password}@{host}/{datab>

# Create the engine with the encoded password in the connection string
engine = create_engine(connection_string)

# Replace 'your_table_name' with the actual name you wish to use for the table
d.to_sql('discharge_notes', con=engine, index=False, if_exists='replace')

rad=pd.read_csv('/tmp/radiology.csv')
rad_det=pd.read_csv('/tmp/radiology_detail.csv')

r = pd.merge(rad, rad_det, on='note_id', how='inner')
r=r.drop(columns=['subject_id_x'])
r=r.rename(columns={"subject_id_y": "subject_id"})

from urllib.parse import quote_plus
from sqlalchemy import create_engine

# Original password with special characters
raw_password = "password"

# URL-encode the password
encoded_password = quote_plus(raw_password)

# Now, build your connection string using the encoded password
username = 'root'
host = 'localhost'
database_name = 'openemr'
connection_string = f"mysql+pymysql://{username}:{encoded_password}@{host}/{datab>

# Create the engine with the encoded password in the connection string
engine = create_engine(connection_string)

# Replace 'your_table_name' with the actual name you wish to use for the table
r.to_sql('radiology_notes', con=engine, index=False, if_exists='replace')

