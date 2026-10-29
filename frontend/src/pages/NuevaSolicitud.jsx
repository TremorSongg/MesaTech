import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useApi } from '../hooks/useApi';
import styles from './Page.module.css';

export default function NuevaSolicitud() {
  const api = useApi();
  const navigate = useNavigate();
  const [categorias, setCategorias] = useState([]);
  const [prioridades, setPrioridades] = useState([]);
  const [form, setForm] = useState({ titulo: '', descripcion: '', categoriaId: '', prioridadId: '' });

  // Objetos completos para poder enviar los datos desnormalizados al backend
  const catObj = categorias.find((c) => String(c.id) === String(form.categoriaId));
  const prioObj = prioridades.find((p) => String(p.id) === String(form.prioridadId));
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    // Las categorías salen de la copia local de Solicitudes (sincronizada por RabbitMQ);
    // las prioridades siguen viniendo del catálogo.
    Promise.all([
      api.get('/v1/solicitudes/categorias'),
      api.get('/v1/catalogo/prioridades'),
    ]).then(([cats, prios]) => {
      setCategorias(cats.filter((c) => c.activo));
      setPrioridades(prios.filter((p) => p.activo));
      if (cats.length) setForm((f) => ({ ...f, categoriaId: cats[0].id }));
      if (prios.length) setForm((f) => ({ ...f, prioridadId: prios[0].id }));
    }).catch(() => setError('No se pudo cargar el catálogo.'));
  }, []);

  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  const submit = async (e) => {
    e.preventDefault();
    if (!form.titulo.trim() || !form.descripcion.trim()) {
      setError('Título y descripción son obligatorios.');
      return;
    }
    try {
      setSubmitting(true);
      setError(null);
      await api.post('/v1/solicitudes', {
        titulo: form.titulo,
        descripcion: form.descripcion,
        categoriaId: Number(form.categoriaId),
        categoriaNombre: catObj?.nombre,
        prioridadId: Number(form.prioridadId),
        prioridadNombre: prioObj?.nombre,
        prioridadNivel: prioObj?.nivel,
      });
      navigate('/mis-solicitudes');
    } catch (e) {
      setError(e.response?.data?.error || 'Error al crear la solicitud.');
      setSubmitting(false);
    }
  };

  return (
    <div className={styles.page}>
      <div className={styles.header}>
        <div>
          <h1 className={styles.title}>Nueva Solicitud</h1>
          <p className={styles.sub}>Completa el formulario para registrar tu solicitud</p>
        </div>
      </div>

      <div className={styles.content}>
        <form className={styles.formCard} onSubmit={submit}>
          <div className={styles.fgrid}>
            <div className={`${styles.fg} ${styles.full}`}>
              <label className={styles.flabel}>Título <span style={{ color: '#EF4444' }}>*</span></label>
              <input className={styles.finput} value={form.titulo} onChange={set('titulo')} placeholder="Ej: PC no enciende en área de ventas" />
            </div>

            <div className={styles.fg}>
              <label className={styles.flabel}>Categoría <span style={{ color: '#EF4444' }}>*</span></label>
              <select className={styles.fselect} value={form.categoriaId} onChange={set('categoriaId')}>
                {categorias.map((c) => (
                  <option key={c.id} value={c.id}>{c.nombre}</option>
                ))}
              </select>
              {categorias.length === 0 && (
                <span style={{ fontSize: 12, color: '#6B7280' }}>
                  Aún no hay categorías disponibles en Solicitudes. Se sincronizan desde el catálogo de forma asíncrona.
                </span>
              )}
            </div>

            <div className={styles.fg}>
              <label className={styles.flabel}>Prioridad <span style={{ color: '#EF4444' }}>*</span></label>
              <select className={styles.fselect} value={form.prioridadId} onChange={set('prioridadId')}>
                {prioridades.map((p) => (
                  <option key={p.id} value={p.id}>{p.nombre} — Nivel {p.nivel}</option>
                ))}
              </select>
            </div>

            <div className={`${styles.fg} ${styles.full}`}>
              <label className={styles.flabel}>Descripción <span style={{ color: '#EF4444' }}>*</span></label>
              <textarea className={styles.ftextarea} rows={4} value={form.descripcion} onChange={set('descripcion')} placeholder="Describe el problema con el mayor detalle posible…" />
            </div>
          </div>

          {error && <p style={{ color: '#DC2626', fontSize: 13, marginTop: 12 }}>{error}</p>}

          <div className={styles.faction}>
            <button className={styles.btnAccent} type="submit" disabled={submitting}>
              {submitting ? 'Enviando…' : 'Enviar solicitud'}
            </button>
            <button type="button" className={styles.btnGhost} onClick={() => navigate('/mis-solicitudes')}>
              Cancelar
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
