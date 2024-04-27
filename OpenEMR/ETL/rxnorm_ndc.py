import pandas as pd

# Use '\t' for tab-delimited data
rxnconso = pd.read_csv('/tmp/RXNCONSO.RRF', sep='\t', encoding='latin1')

conso = rxnconso[(rxnconso['SAB'] == "RXNORM") ]

column_names = ['RXCUI', 'LUI', 'SUI', 'RXAUI', 'STYPE', 'CODE', 'ATUI', 'SATUI', 'ATN', 'SAB', 'ATV', 'SUPPRESS', 'CVF', 'nan']

# Load the CSV file, specifying column names, ensuring no column is used as an index
rxnsat = pd.read_csv('/tmp/RXNSAT.RRF', sep='|', header=None, names=column_names, encoding='latin1')

sat = rxnsat[(rxnsat['SAB'] == "RXNORM") & (rxnsat['ATN'] == "NDC")]

conso = conso[['RXCUI', 'RXAUI', 'SAB', 'CODE', 'STR']]
sat = sat[['RXCUI', 'RXAUI', 'ATN', 'ATV', 'SAB', 'CODE']]

# Remove exactly two leading zeros from the 'CODE' column
sat['CODE'] = sat['CODE'].astype(str).str.lstrip('0')
sat['ATV'] = sat['ATV'].astype(str).str.lstrip('0')

# Performing an inner join on 'CODE'
c_ndc = pd.merge(conso, sat, on='CODE', how='inner')

# Renaming columns from _x to _conso and _y to _sat
c_ndc = c_ndc.rename(columns=lambda x: x.replace('_x', '_conso').replace('_y', '_sat'))


c_ndc = c_ndc[
    (c_ndc['RXCUI_conso'] == c_ndc['RXCUI_sat']) &
    (c_ndc['RXAUI_conso'] == c_ndc['RXAUI_sat'])
]

ndc = c_ndc[['RXCUI_conso', 'RXAUI_conso', 'SAB_conso', 'ATV', 'STR', 'ATN']]


ndc = ndc.rename(columns=lambda x: x.replace('_conso', ''))

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
connection_string = f"mysql+pymysql://{username}:{encoded_password}@{host}/{database_name}"

# Create the engine with the encoded password in the connection string
engine = create_engine(connection_string)


ndc.to_sql('rxnorm_ndc', con=engine, index=False, if_exists='replace')
