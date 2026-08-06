#!/usr/bin/env node

const https = require('https');
const { URL } = require('url');

/** UI実装に不要なキー一覧 */
const KEYS_TO_REMOVE = new Set([
  'absoluteBoundingBox',
  'absoluteRenderBounds',
  'absoluteTransform',
  'transitionNodeID',
  'transitionDuration',
  'transitionEasing',
  'exportSettings',
  'reactions',
  'interactions',
  'scrollBehavior',
  'pluginData',
  'sharedPluginData',
  'documentationLinks',
  'remote',
  'description',
  'overrides',
  'styleOverrideTable',
  'key',
  'componentPropertyDefinitions',
  'componentProperties',
]);

/**
 * コマンドライン引数をパースする
 */
function parseArgs() {
  const args = process.argv.slice(2);
  const result = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--url' && args[i + 1]) {
      result.url = args[++i];
    } else if (args[i] === '--token' && args[i + 1]) {
      result.token = args[++i];
    } else if (args[i] === '--output' && args[i + 1]) {
      result.output = args[++i];
    }
  }
  return result;
}

/**
 * FigmaのURLからfileKeyとnodeIdを抽出する
 */
function parseFigmaUrl(figmaUrl) {
  const url = new URL(figmaUrl);
  const pathParts = url.pathname.split('/');

  const typeIndex = pathParts.findIndex(p => p === 'file' || p === 'design' || p === 'proto');
  if (typeIndex === -1 || !pathParts[typeIndex + 1]) {
    throw new Error('FigmaのURLからfile keyを抽出できませんでした');
  }

  const fileKey = pathParts[typeIndex + 1];
  const rawNodeId = url.searchParams.get('node-id');

  if (!rawNodeId) {
    throw new Error('URLにnode-idパラメータが見つかりませんでした');
  }

  const nodeId = decodeURIComponent(rawNodeId);

  return { fileKey, nodeId };
}

/**
 * Figma APIを呼び出してノードのJSONを取得する
 */
function fetchFigmaNode(fileKey, nodeId, token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.figma.com',
      path: `/v1/files/${fileKey}/nodes?ids=${encodeURIComponent(nodeId)}`,
      headers: { 'X-Figma-Token': token },
    };

    https.get(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode !== 200) {
          reject(new Error(`Figma APIエラー (${res.statusCode}): ${data}`));
          return;
        }
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(new Error(`JSONパースエラー: ${e.message}`));
        }
      });
    }).on('error', reject);
  });
}

/**
 * 不要なキーを再帰的に削除して軽量化する
 */
function simplify(node) {
  if (Array.isArray(node)) {
    return node.map(simplify);
  }
  if (node !== null && typeof node === 'object') {
    const result = {};
    for (const [key, value] of Object.entries(node)) {
      if (!KEYS_TO_REMOVE.has(key)) {
        result[key] = simplify(value);
      }
    }
    return result;
  }
  return node;
}

async function main() {
  const args = parseArgs();

  if (!args.url) {
    console.error('エラー: --url オプションでFigmaのURLを指定してください');
    process.exit(1);
  }

  // トークンの優先順位: --token > FIGMA_API_TOKEN > FIGMA_TOKEN（後方互換）
  const token = args.token || process.env.FIGMA_API_TOKEN || process.env.FIGMA_TOKEN;
  if (!token) {
    console.error('エラー: --token オプションまたは FIGMA_API_TOKEN 環境変数でAPIトークンを指定してください');
    process.exit(1);
  }

  let fileKey, nodeId;
  try {
    ({ fileKey, nodeId } = parseFigmaUrl(args.url));
  } catch (e) {
    console.error(`URLパースエラー: ${e.message}`);
    process.exit(1);
  }

  let raw;
  try {
    raw = await fetchFigmaNode(fileKey, nodeId, token);
  } catch (e) {
    console.error(`APIエラー: ${e.message}`);
    process.exit(1);
  }

  const simplified = simplify(raw);
  const output = JSON.stringify(simplified, null, 2);

  if (args.output) {
    require('fs').writeFileSync(args.output, output, 'utf8');
    console.error(`✅ 保存しました: ${args.output}`);
  } else {
    console.log(output);
  }
}

main();
