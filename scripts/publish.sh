#!/bin/bash
# Attempt to publish articles to Medium
# Usage: ./scripts/publish.sh [draft|publish]
#
# ⚠️ WARNING: Medium API is deprecated and may not work.
# This script is provided as-is with no guarantee of functionality.
# Manual posting is recommended.

set -e

MODE="${1:-draft}"
API_URL="https://api.medium.com/v1"
IDS_FILE="medium_article_ids.json"

# Initialize IDs file if not exists
if [ ! -f "$IDS_FILE" ]; then
  echo "{}" > "$IDS_FILE"
fi

# Check required environment variables
if [ -z "$MEDIUM_TOKEN" ]; then
  echo "Warning: MEDIUM_TOKEN is not set"
  echo "Medium API is deprecated. Manual posting is recommended."
  exit 0
fi

# Parse frontmatter
parse_frontmatter() {
  local file="$1"
  local key="$2"
  sed -n '/^---$/,/^---$/p' "$file" | grep "^${key}:" | sed "s/^${key}:[[:space:]]*//" | tr -d '"'
}

# Get article body (after frontmatter)
get_body() {
  local file="$1"
  sed '1,/^---$/d' "$file" | sed '1,/^---$/d'
}

# Get tags as array
get_tags() {
  local file="$1"
  sed -n '/^---$/,/^---$/p' "$file" | grep -A100 "^tags:" | grep "^  - " | sed 's/^  - //' | tr -d '"' | head -5
}

# Get user ID
get_user_id() {
  response=$(curl -s -X GET "${API_URL}/me" \
    -H "Authorization: Bearer $MEDIUM_TOKEN" \
    -H "Content-Type: application/json")
  echo "$response" | jq -r '.data.id // empty'
}

echo "Attempting to get Medium user ID..."
user_id=$(get_user_id)

if [ -z "$user_id" ]; then
  echo "Error: Could not get Medium user ID. API may be unavailable."
  echo "Please try manual posting at https://medium.com/new-story"
  exit 0
fi

echo "User ID: $user_id"

for file in posts/*.md; do
  if [ ! -f "$file" ] || [ "$file" = "posts/.gitkeep" ]; then
    continue
  fi

  filename=$(basename "$file" .md)
  echo "Processing: $file"

  # Extract metadata
  title=$(parse_frontmatter "$file" "title")
  canonical_url=$(parse_frontmatter "$file" "canonical_url")
  body=$(get_body "$file")
  tags=$(get_tags "$file")

  # Check if already posted
  post_id=$(jq -r ".\"$filename\" // empty" "$IDS_FILE")

  if [ -n "$post_id" ]; then
    echo "Article already posted: $post_id"
    echo "Medium API does not support updating posts."
    continue
  fi

  # Set publish status based on mode
  if [ "$MODE" = "publish" ]; then
    publish_status="public"
  else
    publish_status="draft"
  fi

  # Build tags array
  tags_json="[]"
  if [ -n "$tags" ]; then
    tags_json=$(echo "$tags" | jq -R -s -c 'split("\n") | map(select(length > 0))')
  fi

  # Build payload
  payload=$(jq -n \
    --arg title "$title" \
    --arg content "$body" \
    --arg contentFormat "markdown" \
    --argjson tags "$tags_json" \
    --arg canonicalUrl "$canonical_url" \
    --arg publishStatus "$publish_status" \
    '{
      title: $title,
      contentFormat: $contentFormat,
      content: $content,
      tags: $tags,
      canonicalUrl: (if $canonicalUrl != "" and $canonicalUrl != "null" then $canonicalUrl else null end),
      publishStatus: $publishStatus
    }')

  echo "Creating post with status: $publish_status"
  response=$(curl -s -X POST "${API_URL}/users/${user_id}/posts" \
    -H "Authorization: Bearer $MEDIUM_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload")

  new_id=$(echo "$response" | jq -r '.data.id // empty')
  if [ -n "$new_id" ]; then
    jq --arg filename "$filename" --arg id "$new_id" \
      '.[$filename] = $id' "$IDS_FILE" > tmp.json && mv tmp.json "$IDS_FILE"
    echo "Saved post ID: $new_id"
    url=$(echo "$response" | jq -r '.data.url // empty')
    echo "Post URL: $url"
  else
    error=$(echo "$response" | jq -r '.errors // empty')
    echo "Error or API unavailable: $error"
    echo "Manual posting recommended: https://medium.com/new-story"
  fi
done

echo "Done!"
