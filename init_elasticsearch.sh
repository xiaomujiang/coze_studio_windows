#!/bin/sh
set -e

echo "Starting Elasticsearch setup..."

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch..."
while ! curl -f http://coze-elasticsearch:9200/_cat/health >/dev/null 2>&1; do
  echo "Waiting for Elasticsearch to be ready..."
  sleep 2
done

echo "Elasticsearch is ready!"

# Check if smartcn plugin is installed
echo "Checking smartcn plugin..."
if curl -s http://coze-elasticsearch:9200/_cat/plugins | grep -q "analysis-smartcn"; then
  echo "✅ smartcn plugin is installed"
else
  echo "❌ smartcn plugin not found"
  exit 1
fi

# Create index templates and indices
echo "Setting up index templates..."

# coze_resource template
echo "Creating coze_resource template..."
cat > /tmp/coze_resource.json << 'EOF'
{
  "index_patterns": ["coze_resource*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "analysis": {
        "analyzer": {
          "smartcn_analyzer": {
            "type": "custom",
            "tokenizer": "smartcn_tokenizer"
          }
        }
      }
    },
    "mappings": {
      "properties": {
        "content": {
          "type": "text",
          "analyzer": "smartcn_analyzer"
        },
        "title": {
          "type": "text",
          "analyzer": "smartcn_analyzer"
        }
      }
    }
  }
}
EOF

curl -X PUT "http://coze-elasticsearch:9200/_index_template/coze_resource" \
  -H "Content-Type: application/json" \
  -d @/tmp/coze_resource.json

# Create coze_resource index
curl -X PUT "http://coze-elasticsearch:9200/coze_resource" -H "Content-Type: application/json"

# project_draft template
echo "Creating project_draft template..."
cat > /tmp/project_draft.json << 'EOF'
{
  "index_patterns": ["project_draft*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "analysis": {
        "analyzer": {
          "smartcn_analyzer": {
            "type": "custom",
            "tokenizer": "smartcn_tokenizer"
          }
        }
      }
    },
    "mappings": {
      "properties": {
        "content": {
          "type": "text",
          "analyzer": "smartcn_analyzer"
        },
        "title": {
          "type": "text",
          "analyzer": "smartcn_analyzer"
        }
      }
    }
  }
}
EOF

curl -X PUT "http://coze-elasticsearch:9200/_index_template/project_draft" \
  -H "Content-Type: application/json" \
  -d @/tmp/project_draft.json

# Create project_draft index
curl -X PUT "http://coze-elasticsearch:9200/project_draft" -H "Content-Type: application/json"

# Set refresh intervals
curl -X PUT "http://coze-elasticsearch:9200/coze_resource/_settings" \
  -H 'Content-Type: application/json' \
  -d '{"index": {"refresh_interval": "10ms"}}'

curl -X PUT "http://coze-elasticsearch:9200/project_draft/_settings" \
  -H 'Content-Type: application/json' \
  -d '{"index": {"refresh_interval": "10ms"}}'

echo "✅ Elasticsearch setup completed successfully!" 