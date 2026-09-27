# Cekping Protocol

Definisi gRPC (Protocol Buffers) antara **Cekping Agent** ([cekping-agent](https://github.com/awandataindonesia/cekping-agent)) dan server Cekping. Repo ini adalah satu-satunya sumber kebenaran untuk protokol tersebut; agent dan server sama-sama mengimpor package Go dari sini.

## Pemakaian (Go)

```bash
go get github.com/awandataindonesia/cekping-protocol@latest
```

```go
import protocol "github.com/awandataindonesia/cekping-protocol"

client := protocol.NewCekpingServiceClient(conn)
```

## Path gRPC

| Service | Path | Status |
|---|---|---|
| `CekpingService` | `/protocol.CekpingService/Connect` | Utama, dipakai agent baru |
| `PingveService` | `/protocol.PingveService/Connect` | Deprecated, untuk agent lama (sebelum protocol v1.1.0) |

Keduanya identik (message sama). Server **wajib mendaftarkan keduanya** ke handler yang sama:

```go
protocol.RegisterCekpingServiceServer(s, handler)
protocol.RegisterPingveServiceServer(s, handler) // agent lama
```

Agent baru memakai `CekpingService`. Jika server menjawab `codes.Unimplemented` (server lama), agent kembali ke `PingveService`.

## Alur Singkat

1. Agent membuka stream `Connect` dan mengirim `AuthRequest` (token probe) sebagai pesan pertama.
2. Server membalas `AuthResponse`. Jika sukses, agent mengirim `Heartbeat` tiap 5 detik.
3. Server mengirim `PingTask` / `MTRTask` / `CancelTask`.
4. Agent men-stream `PingResult` / `MTRResult` per paket/hop (`is_final=false`), lalu satu pesan penutup `is_final=true`.

## ⚠️ Kompatibilitas Wire

Agent sudah terpasang di banyak mesin volunteer, jadi perubahan harus selalu **backward-compatible**:

- **Jangan** mengganti `package protocol` atau nama service `CekpingService` / `PingveService`. Keduanya membentuk path gRPC yang di-dial agent. ("Pingve" adalah codename awal proyek.) `PingveService` baru boleh dihapus jika sudah tidak ada agent lama yang terkoneksi.
- **Jangan** mengubah atau memakai ulang nomor field. Field yang dihapus harus di-`reserved`.
- Menambah field / message / varian `oneof` baru aman.

## Mengubah Protokol

Butuh toolchain dengan versi yang sama dengan header file hasil generate (lihat `Makefile`):

- `protoc` v33.4: [unduh di sini](https://github.com/protocolbuffers/protobuf/releases/tag/v33.4)
- plugin Go: `make tools`

```bash
# edit cekping.proto, lalu:
make generate
go build ./...
```

Commit `.proto` beserta file `*.pb.go` hasil generate. CI akan gagal bila keduanya tidak sinkron.

## Rilis

Versi mengikuti [SemVer](https://semver.org) lewat git tag (`vX.Y.Z`). Setelah tag dibuat, update dependency di agent dan server:

```bash
go get github.com/awandataindonesia/cekping-protocol@vX.Y.Z
```

Urutan deploy: **server dulu, baru agent.** Server harus sudah mengenal pesan baru sebelum agent mengirimnya.
