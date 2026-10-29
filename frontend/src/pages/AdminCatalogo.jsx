import { useState, useEffect, useCallback } from 'react';
import { useApi } from '../hooks/useApi';
import styles from './Page.module.css';

export default function AdminCatalogo() {
  const api = useApi();
  const [categorias, setCategorias] = useState([]);
  const [prioridades, setPrioridades] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modalCat, setModalCat] = useState(null); // null | {id?, nombre, descripcion, activo}
  const [savingCat, setSavingCat] = useState(false);
  // Categorías ya disponibles en Solicitudes (copia local) y las recién creadas que esperan sincronizar
  const [localIds, setLocalIds] = useState(new Set());
  const [pendientes, setPendientes] = useState([]);

  const cargarLocales = useCallback(async () => {
    try {
      const locales = await api.get('/v1/solicitudes/categorias');
      setLocalIds(new Set(locales.map((c) => c.id)));
      return locales;
    } catch {
      return null;
    }
  }, []);

  const cargar = useCallback(async () => {
    try {
      setLoading(true);
      const [cats, prios] = await Promise.all([
        api.get('/v1/catalogo/categorias'),
        api.get('/v1/catalogo/prioridades'),
      ]);
      setCategorias(cats);
      setPrioridades(prios);
      await cargarLocales();
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { cargar(); }, [cargar]);

  // Mientras haya categorías nuevas sin sincronizar, consulta Solicitudes cada 2 s (máx. 60 s)
  useEffect(() => {
    if (pendientes.length === 0) return undefined;
    const inicio = Date.now();
    const timer = setInterval(async () => {
      const locales = await cargarLocales();
      const ids = new Set((locales || []).map((c) => c.id));
      setPendientes((p) => p.filter((id) => !ids.has(id)));
      if (Date.now() - inicio > 60000) setPendientes([]);
    }, 2000);
    return () => clearInterval(timer);
  }, [pendientes.length > 0]);

  const abrirNuevaCat = () => setModalCat({ nombre: '', descripcion: '', activo: true });
  const abrirEditCat = (c) => setModalCat({ ...c });

  const guardarCat = async () => {
    if (!modalCat.nombre.trim()) return;
    try {
      setSavingCat(true);
      if (modalCat.id) {
        await api.put(`/v1/catalogo/categorias/${modalCat.id}`, modalCat);
      } else {
        const creada = await api.post('/v1/catalogo/categorias', modalCat);
        // La publicación en RabbitMQ fue confirmada; Solicitudes la recibe de forma asíncrona
        setPendientes((p) => [...p, creada.id]);
      }
      setModalCat(null);
      cargar();
    } catch (e) {
      alert(e.response?.data?.error || 'Error al guardar.');
      // Si el catálogo la guardó pero no se publicó el evento, igual aparece en la lista
      cargar();
    } finally {
      setSavingCat(false);
    }
  };

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>Catálogo</h1>
          <p className={styles.sub}>Gestión de categorías y prioridades</p>
        </div>
      </div>

      <div className={styles.content}>
        {loading ? (
          <div className={styles.empty}>Cargando…</div>
        ) : (
          <div className={styles.catGrid}>
            {/* Categorías */}
            <div className={styles.card}>
              <div className={styles.cardHead}>
                <span className={styles.cardTitle}>Categorías</span>
                <button className={styles.btnAccent} onClick={abrirNuevaCat}>+ Nueva</button>
              </div>
              <div className={styles.tableWrap}>
                <table className={styles.table}>
                  <thead>
                    <tr><th>#</th><th>Nombre</th><th>Estado</th><th>En Solicitudes</th><th></th></tr>
                  </thead>
                  <tbody>
                    {categorias.map((c) => (
                      <tr key={c.id}>
                        <td><span className={styles.solId}>{c.id}</span></td>
                        <td>
                          <div className={styles.solTitle}>{c.nombre}</div>
                          <div className={styles.solMeta}>{c.descripcion}</div>
                        </td>
                        <td>
                          <span className={c.activo ? styles.badgeActive : styles.badgeInactive}>
                            {c.activo ? 'Activa' : 'Inactiva'}
                          </span>
                        </td>
                        <td>
                          {localIds.has(c.id) ? (
                            <span className={styles.badgeActive}>Disponible</span>
                          ) : pendientes.includes(c.id) ? (
                            <span className={styles.badgeInactive}>Sincronizando…</span>
                          ) : (
                            <span className={styles.badgeInactive}>No sincronizada</span>
                          )}
                        </td>
                        <td>
                          <button className={styles.btnGhost} onClick={() => abrirEditCat(c)}>Editar</button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Prioridades (sólo lectura en esta versión) */}
            <div className={styles.card}>
              <div className={styles.cardHead}>
                <span className={styles.cardTitle}>Prioridades</span>
              </div>
              <div className={styles.tableWrap}>
                <table className={styles.table}>
                  <thead>
                    <tr><th>Nombre</th><th>Nivel</th><th>Estado</th></tr>
                  </thead>
                  <tbody>
                    {prioridades.map((p) => (
                      <tr key={p.id}>
                        <td className={styles.solTitle}>{p.nombre}</td>
                        <td><span className={styles.solMeta}>Nivel {p.nivel}</span></td>
                        <td>
                          <span className={p.activo ? styles.badgeActive : styles.badgeInactive}>
                            {p.activo ? 'Activa' : 'Inactiva'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}
      </div>

      {modalCat && (
        <div className={styles.overlay} onClick={() => setModalCat(null)}>
          <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
            <h2 className={styles.modalTitle}>{modalCat.id ? 'Editar categoría' : 'Nueva categoría'}</h2>
            <div className={styles.fg} style={{ marginBottom: 12 }}>
              <label className={styles.flabel}>Nombre *</label>
              <input className={styles.finput} value={modalCat.nombre}
                onChange={(e) => setModalCat((m) => ({ ...m, nombre: e.target.value }))} />
            </div>
            <div className={styles.fg} style={{ marginBottom: 16 }}>
              <label className={styles.flabel}>Descripción</label>
              <input className={styles.finput} value={modalCat.descripcion || ''}
                onChange={(e) => setModalCat((m) => ({ ...m, descripcion: e.target.value }))} />
            </div>
            <div style={{ display: 'flex', gap: 10 }}>
              <button className={styles.btnAccent} onClick={guardarCat} disabled={savingCat}>
                {savingCat ? 'Guardando…' : 'Guardar'}
              </button>
              <button className={styles.btnGhost} onClick={() => setModalCat(null)}>Cancelar</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
