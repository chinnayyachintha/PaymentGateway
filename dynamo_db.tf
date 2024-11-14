
# Create DynamoDB table for storing encrypted card data
resource "aws_dynamodb_table" "encrypted_card_data" {
  name           = "EncryptedCardData"
  hash_key       = "card_id"   # Use your primary key
  range_key      = "timestamp" # Optional: if you use a range key
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "card_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "encrypted_data" # Ensure this is indexed if needed
    type = "S"
  }

  # Example of adding a Global Secondary Index (GSI)
  global_secondary_index {
    name            = "EncryptedDataIndex"
    hash_key        = "encrypted_data"
    projection_type = "ALL"
    read_capacity   = 5
    write_capacity  = 5
  }
}
