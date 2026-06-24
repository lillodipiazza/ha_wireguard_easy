# Home Assistant add-on: wg-easy

Un repository di add-on per Home Assistant che fornisce **[wg-easy](https://github.com/wg-easy/wg-easy)** — WireGuard VPN con interfaccia web — integrato con Home Assistant (Ingress, configurazione persistente, setup automatico al primo avvio).

```
ha_wireguard_easy/
└── wg-easy/                  # l'add-on
    ├── config.yaml           # configurazione add-on (HA)
    ├── Dockerfile            # FROM immagine ufficiale wg-easy v15
    ├── entrypoint.sh         # persistenza + setup automatico + avvio
    ├── README.md             # documentazione d'uso
    ├── CHANGELOG.md
    └── translations/
        └── en.yaml           # etichette opzioni (IT)
```

## Installazione rapida

1. **Carica il repository in Home Assistant**
   - *Settings → Add-ons → Add-on Store → ⋮ → Repositories*
   - Aggiungi l'URL di questo repo Git, poi **Reload**.
   - *(oppure copia la cartella `wg-easy/` in `/addons/` via Samba/SFTP).*
2. **Installa** l'add-on *wg-easy* dalla Add-on Store.
3. **Configura** almeno `host` (endpoint pubblico), `username` e `password`.
4. **Apri la porta UDP** (default `51820`) sul router verso Home Assistant.
5. **Avvia** l'add-on e apri la UI dall'icona nella barra laterale (Ingress).

➡️ Dettagli completi nel README dell'add-on: [`wg-easy/README.md`](wg-easy/README.md).

## Come funziona (in breve)

- Costruisce sull'immagine ufficiale `ghcr.io/wg-easy/wg-easy:15`.
- Salva tutti i dati in modo persistente (`/etc/wireguard` → `/data/wg-easy`).
- Al primo avvio configura automaticamente wg-easy tramite le opzioni dell'add-on.
- Usa la rete host con privilegi `NET_ADMIN`/`SYS_MODULE` così i client VPN raggiungono tutta la rete di casa.

## Note

- Non affiliato al progetto wg-easy. wg-easy è distribuito con licenza **AGPL-3.0**.
- Architetture supportate: **amd64**, **aarch64** (no armv7 — l'immagine upstream non lo fornisce).
