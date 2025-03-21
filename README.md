# hyperledger-fabric-traceability-k8s-rds-offchain-analytics

以下は、**トレーサビリティを意識したMVP**（最小実装）システムの設計例です。  
- **Hyperledger Fabric等のブロックチェーン**との連携は省略または後回しにして、まずはRDBでオフチェーン部分のみ実装する形を想定。  
- ここを出発点に、必要に応じてブロックチェーン連携やマイクロサービス化を後から拡張できます。

---

# 1. DBテーブル設計 (RDB)

## 1-1. parts (部品マスタ)

| カラム名              | 型 (例)    | 説明                                                      |
|-----------------------|-----------|-----------------------------------------------------------|
| **part_id (PK)**      | BIGINT    | 部品ID (主キー)                                          |
| part_name             | VARCHAR   | 部品名                                                   |
| owner_name            | VARCHAR   | 所有者・工場・組織等 (例: “FactoryA”, “CompanyB”)          |
| status                | VARCHAR   | 現在ステータス (例: “MANUFACTURED”, “SHIPPED”, etc.)      |
| created_at            | DATETIME  | 登録日時                                                 |
| updated_at            | DATETIME  | 更新日時                                                 |

- **ポイント**  
  - MVPではシンプルに「名前」「所有者」「ステータス」くらいに留めておく。  
  - 将来ブロックチェーンと連携するときは、**ブロックチェーン上のTxハッシュ**や**block_number**などを持たせてもOK。

## 1-2. part_events (イベント履歴テーブル)

| カラム名                | 型 (例)    | 説明                                                                           |
|-------------------------|-----------|--------------------------------------------------------------------------------|
| **event_id (PK)**       | BIGINT    | イベントID (主キー)                                                            |
| **part_id (FK)**        | BIGINT    | 紐づく部品ID (parts.part_id)                                                   |
| event_type              | VARCHAR   | イベント種別 (例: “MANUFACTURED”, “SHIPPED”, “RECEIVED”, etc.)                 |
| location                | VARCHAR   | イベント発生場所 (工場や倉庫など)                                               |
| metadata                | TEXT      | 補足情報 (ロット番号、数量、担当者など自由記述)                                |
| bc_tx_hash              | VARCHAR   | (後からブロックチェーン連携した際) Txハッシュの格納に使う                      |
| bc_block_number         | BIGINT    | (同上) ブロック番号等                                                           |
| bc_timestamp            | DATETIME  | (同上) ブロックチェーン上の承認時刻                                             |
| created_at              | DATETIME  | イベント登録日時                                                               |

- **ポイント**  
  - MVP段階では bc_tx_hash, bc_block_number, bc_timestamp はNULL可。後でブロックチェーン連携したら格納できる。  
  - ここにひたすらイベントを追加していくことで、トレーサビリティを担保。

## 1-3. (任意) users (ユーザー管理)

| カラム名            | 型 (例)    | 説明                                        |
|---------------------|-----------|---------------------------------------------|
| **user_id (PK)**    | BIGINT    | ユーザーID (主キー)                         |
| username            | VARCHAR   | ログイン名                                  |
| password_hash       | VARCHAR   | パスワードのハッシュ値                      |
| role                | VARCHAR   | 役割(“USER”, “ADMIN”など)                   |
| created_at          | DATETIME  | 登録日時                                    |
| updated_at          | DATETIME  | 更新日時                                    |

- ログイン機能が欲しい場合は用意します。MVPで認証を省くなら不要です。

---

# 2. ウェブシステム (画面) のサンプル構成

**フレームワーク例**  
- フロント: **Next.js / React**  
- バックエンド: **Go (Gin)** or Node.js(Express)  
- DB: MySQL / PostgreSQL など (MVPならSQLiteでも可)

## 2-1. ログイン画面 (任意)

- **URL例**: `/login`  
- ユーザー名・パスワードを入力 → バックエンドAPI認証 → セッションorJWTでログイン  
- MVPでは省略可。開発時は固定ユーザーでもOK。

## 2-2. 部品一覧画面 (Parts List)

- **URL例**: `/parts`  
- partsテーブルを `SELECT * FROM parts` で取得し、一覧表示。  
- 表示カラム例: part_id, part_name, owner_name, status, updated_at  
- 「詳細を見る」ボタンで部品詳細画面へ。

## 2-3. 部品詳細画面 (Part Detail)

- **URL例**: `/parts/:part_id`  
- 指定したpart_idの情報をRDBから取得して表示 (part_name, owner, status など)。  
- さらに part_eventsテーブルから該当part_idのイベント履歴を時系列で表示。  
- **“イベントを追加”**ボタンを用意し、クリックするとイベント登録画面へ遷移。

## 2-4. 新規部品登録画面 (Create Part)

- **URL例**: `/parts/new`  
- 入力項目: part_name, owner_name  
- Submit → バックエンドAPI呼び出し → partsテーブルへINSERT (statusを“MANUFACTURED”など初期値にしておく)  
- 完了後、部品詳細 or 一覧へリダイレクト。

## 2-5. イベント登録画面 (Record Event)

- **URL例**: `/parts/:part_id/add-event`  
- 入力項目: event_type (SelectBox “SHIPPED”, “RECEIVED”など), location, metadata (free text)  
- Submit → バックエンドAPI呼び出し → part_eventsテーブルへINSERT  
- **オプション**: 同時にparts.statusを更新(例: event_type=“SHIPPED”→status=“SHIPPED”)  
- 完了後、部品詳細画面へ戻り、新しいイベントが履歴に追加されるのを確認。

## 2-6. イベント履歴表示 (履歴テーブル)

- **URL例**: `/parts/:part_id#events` (Part Detail画面の下部でもOK)  
- 取得: `SELECT * FROM part_events WHERE part_id = ? ORDER BY created_at DESC`  
- 表示: event_type, location, metadata, created_at  
- MVP段階で十分。将来ブロックチェーン連携している場合は bc_tx_hash 等を併記。

---

# 3. MVPアプリの一連の操作フロー

1. **「部品登録」**  
   - ユーザーが `/parts/new` 画面で part_name, owner_name を入力 → Create Part → DBにINSERT → status=“MANUFACTURED”  
2. **「イベント登録」** (出荷など)  
   - ユーザーが `/parts/:id/add-event` 画面で event_type=“SHIPPED”, location=“FactoryA”などを入力 → Record Event → DBにINSERT  
   - parts.status を “SHIPPED” に更新してもOK  
3. **「部品詳細」**  
   - `/parts/:id` で部品本体と、紐づく part_events を時系列に表示。  
   - イベント履歴が溜まっていき、**“製造→出荷→受領→組立…”** の流れを確認可能。  

---

# 4. 今後の拡張

1. **ブロックチェーン連携**  
   - CreatePart や RecordEvent のタイミングで、**Hyperledger Fabric**のチェーンコード呼び出し(“recordEvent”関数など)を行い、Txハッシュやブロック番号を part_events.bc_tx_hash に格納するなど。  
   - MVPで構築したUIはそのまま使い、**内部でFabric SDK**を呼び出す形に切り替える。

2. **マイクロサービス化**  
   - MVPでは1つのモノリスアプリだが、将来的には「Parts Service」「Events Service」「User/Org Service」を分割してコンテナデプロイ、Kubernetes運用に拡張。

3. **DWH連携 / BI**  
   - 追加で Snowflake/Redshift/BigQuery 等に part_events を送るETLを組み込み、大規模分析やダッシュボード化を実施。  
   - 改ざん防止をFabricに任せつつ、**分析やレポート**はDWH側で行う。

4. **セキュリティ / 認可**  
   - 各画面で「誰がどこまで操作できるか」を細かく制御したり、多要素認証や監査ログを充実化。

---

## まとめ

**MVP**としては:

1. **DBテーブル**: parts（部品マスタ）, part_events（イベント履歴）  
2. **Web画面**:  
   - (1) 部品一覧 → (2) 部品詳細(＋イベント一覧) → (3) 部品新規登録 → (4) イベント登録  
   - (任意) ログイン画面

この構成で「部品とイベント履歴を管理→トレーサビリティ風に表示」する仕組みがサクッと完成します。  
後から**Hyperledger Fabric**や**Kubernetes**, **DWH**を組み込む際も、このMVP設計を基に拡張できるので、最初に作るシステムとして最適です。

以下では、**Hyperledger Fabric 等のブロックチェーンと、従来の RDB/オフチェーンを組み合わせた「ハイブリッド型」**の設計サンプルを示します。要件に応じて、「改ざん不可が必要な最小限のデータ」をオンチェーンに書き込みつつ、**詳細や大量データはRDBに保持**する形です。

---

# 1. システム概要 (ハイブリッド構成)

```
┌───────────────┐
│   Frontend (UI)  │
└───────────────┘
          │
          ▼
┌─────────────────┐        ┌─────────────────────────────────┐
│    Backend       │  -->  │  RDB / Offchain (Detailed Data) │
│  (Microservice)  │  <--  └─────────────────────────────────┘
└─────────────────┘
          │
          ▼
┌─────────────────────────────┐
│Hyperledger Fabric (On-chain)│
│(Chaincode / Blockchain)     │
└─────────────────────────────┘
```

1. **Frontend(UI)**: ユーザーが部品やイベントを登録・編集・閲覧する画面。  
2. **Backend(Microservice)**:  
   - RDB と Fabric 双方を連携する要。  
   - RDB への CRUD と、Fabric へのスマートコントラクト呼び出しを一本化した API を提供。  
3. **RDB/Offchain**:  
   - 大量データや詳細情報、検索・集計を担う。  
   - 例: MySQL/PostgreSQL, もしくは Snowflake/Redshift などのDWH。  
4. **Hyperledger Fabric (On-chain)**:  
   - 改ざん防止が必要な部分のトランザクション・履歴を記録。  
   - Chaincode で「ハッシュの記録」や「簡易メタデータ管理」を行う。

---

# 2. スキーマ設計（例）

## 2-1. RDBテーブル（オフチェーン側）

### parts (詳細マスタ)

| カラム名           | 型 (例)   | 説明                                                         |
|--------------------|----------|--------------------------------------------------------------|
| **part_id (PK)**   | BIGINT   | 部品ID(主キー)                                              |
| part_name          | VARCHAR  | 部品名称                                                     |
| owner_name         | VARCHAR  | 所有者名(工場/組織など)                                     |
| status             | VARCHAR  | ステータス(MANUFACTURED/SHIPPEDなど)                        |
| detail_info        | TEXT     | 詳細情報(サイズやスペックなど)                               |
| bc_hash            | VARCHAR  | オンチェーンに書き込んだ際のハッシュ(後述)                  |
| updated_at         | DATETIME | 更新日時                                                    |

- **ポイント**  
  - RDB側に十分な詳細情報を保持。  
  - **bc_hash**: 部品の主要フィールド(part_name, owner, statusなど)をJSON化してハッシュ化し、ブロックチェーンに書き込んだ場合、そのハッシュ値をRDBにも保存。

### part_events (詳細イベントログ)

| カラム名             | 型 (例)    | 説明                                                                |
|----------------------|-----------|---------------------------------------------------------------------|
| **event_id (PK)**    | BIGINT    | イベントID(主キー)                                                  |
| **part_id (FK)**     | BIGINT    | 紐づく部品ID(parts.part_id)                                         |
| event_type           | VARCHAR   | イベント種別(SHIPPED/RECEIVED等)                                    |
| event_detail         | TEXT      | イベントの詳細(数量/担当者/備考等)                                  |
| bc_tx_hash           | VARCHAR   | オンチェーン取引のTxハッシュ                                        |
| bc_block_number      | BIGINT    | (オプション)ブロック番号                                            |
| bc_event_hash        | VARCHAR   | イベントのメタ情報をハッシュ化してブロックチェーンに登録する際の値 |
| created_at           | DATETIME  | 登録日時                                                            |

- **ポイント**  
  - イベント自体もオフチェーンに詳細保管しつつ、ブロックチェーンにはメタ情報やハッシュを書き込み可能。

---

## 2-2. Fabricチェーンコード(オンチェーン側)

### メインコンセプト

1. **hash-based approach**: RDBにある部品やイベントの主要フィールドをJSONにし、そのハッシュ(SHA-256等)を**チェーンコード**で `PutState`。  
2. **partID + timestamp** などのキーで `PutState(key, hashValue)` するか、より複雑な構造を管理してもOK。  
3. **改ざん検証**:  
   - 後からRDBのデータを再ハッシュして、**チェーン上の値**と一致するか検証。  
   - 一致しなければ改ざんが疑われる。

### サンプルチェーンコード (Go例)

```go
func (s *SmartContract) RecordPartHash(ctx contractapi.TransactionContextInterface, partID, partHash string) error {
   // Key: e.g. "partHash_PARTID"
   key := fmt.Sprintf("partHash_%s", partID)
   return ctx.GetStub().PutState(key, []byte(partHash))
}

func (s *SmartContract) RecordEventHash(ctx contractapi.TransactionContextInterface, eventID, eventHash string) error {
   // Key: e.g. "eventHash_EVENTID"
   key := fmt.Sprintf("eventHash_%s", eventID)
   return ctx.GetStub().PutState(key, []byte(eventHash))
}
```

---

# 3. 処理フロー例

1. **部品登録 (UI→Backend→RDB)**  
   - ユーザーが「part_name, owner, status=MANUFACTURED等」を入力  
   - Backendが partsテーブルにINSERT → part_id を生成  
   - その後、Backendが(オプションで)生成したデータをJSON化しハッシュ化 → Fabricチェーンコード`RecordPartHash(partID, hashValue)`呼び出し  
   - RDBの parts.bc_hash にも hashValue を保存  

2. **イベント登録 (UI→Backend→RDB+Fabric)**  
   - ユーザーが「出荷イベント(SHIPPED), 場所, 数量等」を入力  
   - Backendが part_eventsにINSERT → event_idを生成  
   - その後、(一部メタ情報または全データ)をハッシュ化 → Fabricチェーンコード`RecordEventHash(eventID, eventHash)`  
   - eventHash を part_events.bc_event_hash に格納  
   - optionally, bc_tx_hash などのTx情報をChaincode呼び出し後に取得してDBに保存  

3. **検証 (改ざんチェック)**  
   - 何らかの理由で「part_id=123が改ざんされたのでは？」となったとき  
   - RDBの partsレコードをJSON化→SHA-256などで計算→ Fabricに `GetState("partHash_123")` で取り出した値と比較。  
   - 一致すればOK、一致しなければ改ざんの可能性がある。

---

# 4. 画面サンプル

1. **部品一覧**  
   - RDB内の parts をテーブル表示。  
   - bc_hash が表示されてもいいが、通常は非表示または詳細画面に表示。  

2. **部品詳細**  
   - partsテーブルの情報を出力、bc_hashなどオンチェーン関連項目も確認可能。  
   - イベント一覧(part_events)を表示。bc_event_hash, bc_tx_hash なども表示して改ざん不可アピール。

3. **イベント登録**  
   - “SHIPPED” や “RECEIVED”など event_typeをセレクトボックスで選択。場所や数量などを入力。  
   - Submit → DBにINSERT, → Fabricに hash登録 → RDBに bc_event_hash, bc_tx_hashなどを保存 → リダイレクト。

4. **検証UI(オプション)**  
   - “Verify Integrity” ボタンで部品やイベントのハッシュ再計算→チェーン上のハッシュと比較。  
   - MVPでは省略可。

---

# 5. まとめ

- **Hybridアプローチ**:
  1. **RDB(オフチェーン)** で詳細データ管理・柔軟な検索  
  2. **Fabric(オンチェーン)** で改ざん防止のハッシュ or 簡易メタデータを保存  
- **テーブル例**:
  - parts, part_events に bc_hash / bc_event_hash フィールドを用意し、更新時にFabricのチェーンコードを呼び出すフロー  
- **チェーンコード例**:
  - RecordPartHash, RecordEventHash などを実装して、Key-Value形式でハッシュを保存  
- **フロー**:
  - (1) DBにINSERT → (2) データをハッシュ → (3) Fabricチェーンコード呼び出し → (4) TxハッシュなどをDBに追記  
- **拡張**:
  - K8sによるスケーリング, CI/CD, DWH連携(ETLでSnowflake等に送る), 監査UI などを追加していく。

これが、**ハイブリッド型の基本的な設計サンプル**です。  
必要に応じて**部品マスタ**そのものや**イベント**をフルでオンチェーンに書く・ハッシュにとどめるなど選択し、将来的にマイクロサービス化やBIツール連携を行えば、エンタープライズ向けのトレーサビリティシステムへスムーズに成長させられます。
