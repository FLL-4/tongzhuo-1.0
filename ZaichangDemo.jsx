/**
 * 随心搭使用文档：https://ku.baidu-int.com/d/mfrhJmtqNgXEoi
 *
 * 当前场景图片：
 * ./在场/在场/WebApp/雨夜书房.png
 * ./在场/在场/WebApp/湖畔桌面.png
 * ./在场/在场/WebApp/深夜小屋.png
 */

import React, { useEffect, useMemo, useState } from 'react';

const ROOM_THEMES = [
  {
    name: '雨夜书房',
    src: './在场/在场/WebApp/雨夜书房.png',
    alt: '雨夜中，两个人在像素书房里安静同桌',
    eyebrow: '星期一 · 雨夜',
    title: '一起安静坐一会儿',
    weather: '☂ 小雨 21°C',
    sound: '雨声',
    rainy: true,
  },
  {
    name: '湖畔桌面',
    src: './在场/在场/WebApp/湖畔桌面.png',
    alt: '清晨湖畔，两个人在木屋里安静同桌',
    eyebrow: '星期二 · 湖畔清晨',
    title: '让今天慢慢开始',
    weather: '☀ 晴 17°C',
    sound: '湖水声',
    rainy: false,
  },
  {
    name: '深夜小屋',
    src: './在场/在场/WebApp/深夜小屋.png',
    alt: '深夜山林小屋里，两个人各自安静做事',
    eyebrow: '星期五 · 山林深夜',
    title: '灯还亮着，我也在',
    weather: '☾ 晴 12°C',
    sound: '炉火声',
    rainy: false,
  },
];

const PRESENCE_STATES = [
  { id: 'focus', label: '专注中', icon: '●', note: '灯会一直亮着' },
  { id: 'quiet', label: '安静待着', icon: '☾', note: '暂停所有提醒' },
  { id: 'break', label: '休息一下', icon: '☕', note: '给自己十分钟' },
  { id: 'away', label: '离开一会', icon: '◇', note: '保留桌上的灯' },
];

const INITIAL_TASKS = [
  { id: 1, text: '整理首页文案', done: true },
  { id: 2, text: '补齐方案最后两页', done: false },
  { id: 3, text: '给阿禾回一段留声', done: false },
];

const formatTime = seconds => {
  const minutes = Math.floor(seconds / 60).toString().padStart(2, '0');
  const rest = (seconds % 60).toString().padStart(2, '0');
  return `${minutes}:${rest}`;
};

const Icon = ({ children }) => <span className="zc-icon" aria-hidden="true">{children}</span>;

const ZaichangDemo = () => {
  const [userInfo, setUserInfo] = useState({});
  const [clock, setClock] = useState('23:08');
  const [presence, setPresence] = useState('focus');
  const [stateMenuOpen, setStateMenuOpen] = useState(false);
  const [seconds, setSeconds] = useState(24 * 60 + 18);
  const [running, setRunning] = useState(true);
  const [modal, setModal] = useState(null);
  const [themeIndex, setThemeIndex] = useState(0);
  const [rain, setRain] = useState(true);
  const [ambient, setAmbient] = useState(true);
  const [tasks, setTasks] = useState(INITIAL_TASKS);
  const [recording, setRecording] = useState(false);
  const [recordSeconds, setRecordSeconds] = useState(0);
  const [recordReady, setRecordReady] = useState(false);
  const [delivery, setDelivery] = useState('专注结束后');
  const [voiceCount, setVoiceCount] = useState(1);
  const [toast, setToast] = useState('');
  const [notice, setNotice] = useState(true);

  const activePresence = PRESENCE_STATES.find(item => item.id === presence);
  const completedTasks = tasks.filter(task => task.done).length;
  const nickname = userInfo.nickname || '知知';
  const activeTheme = ROOM_THEMES[themeIndex];

  const rainDrops = useMemo(
    () => Array.from({ length: 54 }, (_, index) => ({
      id: index,
      left: `${(index * 19.7) % 108 - 4}%`,
      height: `${12 + (index % 5) * 4}px`,
      duration: `${0.8 + (index % 7) * 0.11}s`,
      delay: `${-(index % 13) * 0.27}s`,
      opacity: 0.22 + (index % 5) * 0.09,
    })),
    [],
  );

  useEffect(() => {
    const ku = globalThis.Ku;
    if (ku?.getUserInfo) {
      ku.getUserInfo().then(setUserInfo).catch(() => setUserInfo({}));
    }
  }, []);

  useEffect(() => {
    const updateClock = () => {
      setClock(new Date().toLocaleTimeString('zh-CN', {
        hour: '2-digit',
        minute: '2-digit',
        hour12: false,
      }));
    };
    updateClock();
    const interval = window.setInterval(updateClock, 1000);
    return () => window.clearInterval(interval);
  }, []);

  useEffect(() => {
    if (!running || seconds <= 0) return undefined;
    const interval = window.setInterval(() => {
      setSeconds(value => {
        if (value <= 1) {
          setRunning(false);
          showToast('这一段完成了，留声机亮起来了');
          return 0;
        }
        return value - 1;
      });
    }, 1000);
    return () => window.clearInterval(interval);
  }, [running, seconds]);

  useEffect(() => {
    if (!recording) return undefined;
    const interval = window.setInterval(() => {
      setRecordSeconds(value => {
        if (value >= 59) {
          setRecording(false);
          setRecordReady(true);
          return 60;
        }
        return value + 1;
      });
    }, 1000);
    return () => window.clearInterval(interval);
  }, [recording]);

  useEffect(() => {
    if (!toast) return undefined;
    const timeout = window.setTimeout(() => setToast(''), 2200);
    return () => window.clearTimeout(timeout);
  }, [toast]);

  const showToast = message => setToast(message);

  const choosePresence = item => {
    setPresence(item.id);
    setStateMenuOpen(false);
    setRunning(item.id === 'focus');
    showToast(`状态已切换为“${item.label}”`);
  };

  const toggleTask = id => {
    setTasks(current => current.map(task => (
      task.id === id ? { ...task, done: !task.done } : task
    )));
  };

  const toggleRecording = () => {
    if (recording) {
      setRecording(false);
      setRecordReady(recordSeconds > 0);
      return;
    }
    setRecordSeconds(0);
    setRecordReady(false);
    setRecording(true);
  };

  const saveVoice = () => {
    if (!recordReady) return;
    setVoiceCount(value => value + 1);
    setModal(null);
    setRecordReady(false);
    setRecordSeconds(0);
    showToast(`留声会在“${delivery}”抵达`);
  };

  const copyDeskCode = async () => {
    try {
      await navigator.clipboard.writeText('YUZU-2048');
      showToast('同桌码 YUZU-2048 已复制');
    } catch {
      showToast('同桌码：YUZU-2048');
    }
  };

  const playVoice = () => {
    try {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      const context = new AudioContext();
      [392, 523.25, 659.25].forEach((frequency, index) => {
        const oscillator = context.createOscillator();
        const gain = context.createGain();
        oscillator.frequency.value = frequency;
        gain.gain.setValueAtTime(0.001, context.currentTime + index * 0.12);
        gain.gain.linearRampToValueAtTime(0.07, context.currentTime + index * 0.12 + 0.02);
        gain.gain.exponentialRampToValueAtTime(0.001, context.currentTime + index * 0.12 + 0.5);
        oscillator.connect(gain).connect(context.destination);
        oscillator.start(context.currentTime + index * 0.12);
        oscillator.stop(context.currentTime + index * 0.12 + 0.55);
      });
    } catch {
      // Some embedded browsers disable Web Audio. The visual demo still works.
    }
    showToast('正在播放阿禾的留声 · 00:18');
  };

  const closeModal = () => {
    setModal(null);
    if (recording) setRecording(false);
  };

  return (
    <div className="zc-root">
      <main className="zc-desktop">
        <section className="zc-window" aria-label="在场桌面应用 Demo">
          <header className="zc-titlebar">
            <div className="zc-window-controls" aria-hidden="true">
              <span className="zc-dot zc-red" />
              <span className="zc-dot zc-yellow" />
              <span className="zc-dot zc-green" />
            </div>

            <div className="zc-brand">
              <span className="zc-brand-mark">在</span>
              <strong>在场</strong>
            </div>

            <div className="zc-title-status">
              <span>{activeTheme.weather}</span>
              <span>{clock}</span>
            </div>

            <div className="zc-title-actions">
              <button type="button" className="zc-icon-button" title="通知" onClick={() => {
                setNotice(false);
                showToast('阿禾在 3 分钟前加入了同桌');
              }}>
                <Icon>♢</Icon>
                {notice && <i className="zc-notice" />}
              </button>
              <button type="button" className="zc-avatar" title={nickname}>{nickname.slice(0, 1)}</button>
            </div>
          </header>

          <div className="zc-layout">
            <nav className="zc-nav" aria-label="主要功能">
              <div className="zc-nav-group">
                <button type="button" className="zc-nav-button active"><Icon>⌂</Icon><span>在场</span></button>
                <button type="button" className="zc-nav-button" onClick={() => setModal('desk')}><Icon>♧</Icon><span>同桌</span></button>
                <button type="button" className="zc-nav-button" onClick={() => setModal('voice')}>
                  <Icon>◎</Icon><span>留声</span><b>{voiceCount}</b>
                </button>
                <button type="button" className="zc-nav-button" onClick={() => setModal('memory')}><Icon>▤</Icon><span>记忆</span></button>
              </div>
              <button type="button" className="zc-nav-button" onClick={() => setModal('theme')}><Icon>☷</Icon><span>设置</span></button>
            </nav>

            <section className={`zc-stage state-${presence}`} aria-label="像素小屋场景">
              <img src={activeTheme.src} alt={activeTheme.alt} />
              <div className="zc-stage-shade" />
              {rain && activeTheme.rainy && (
                <div className="zc-rain" aria-hidden="true">
                  {rainDrops.map(drop => (
                    <i key={drop.id} style={{
                      left: drop.left,
                      height: drop.height,
                      animationDuration: drop.duration,
                      animationDelay: drop.delay,
                      opacity: drop.opacity,
                    }} />
                  ))}
                </div>
              )}

              <div className="zc-scene-heading">
                <span>{activeTheme.eyebrow}</span>
                <h1>{activeTheme.title}</h1>
              </div>

              <button type="button" className="zc-friend" onClick={() => setModal('desk')}>
                <span className="zc-friend-avatar">禾</span>
                <span><strong>阿禾在这里</strong><small>已专注 18 分钟</small></span>
                <i />
              </button>

              <div className="zc-scene-controls">
                <div className="zc-state-control">
                  <button type="button" className="zc-state-button" onClick={() => setStateMenuOpen(value => !value)}>
                    <i />
                    <span>{activePresence.label}</span>
                    <Icon>⌃</Icon>
                  </button>
                  {stateMenuOpen && (
                    <div className="zc-state-menu">
                      {PRESENCE_STATES.map(item => (
                        <button type="button" key={item.id} onClick={() => choosePresence(item)}>
                          <Icon>{item.icon}</Icon>
                          <span><strong>{item.label}</strong><small>{item.note}</small></span>
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                <div className="zc-timer">
                  <button type="button" onClick={() => setRunning(value => !value)} title={running ? '暂停计时' : '继续计时'}>
                    <Icon>{running ? 'Ⅱ' : '▶'}</Icon>
                  </button>
                  <span><strong>{formatTime(seconds)}</strong><small>方案收尾</small></span>
                  <button type="button" onClick={() => {
                    setSeconds(25 * 60);
                    setRunning(false);
                    showToast('计时器已重置为 25 分钟');
                  }} title="重新计时"><Icon>↻</Icon></button>
                </div>

                <button type="button" className={`zc-sound ${ambient ? 'active' : ''}`} onClick={() => {
                  setAmbient(value => !value);
                  showToast(ambient ? `${activeTheme.sound}已关闭` : `${activeTheme.sound}已打开`);
                }} title={ambient ? `关闭${activeTheme.sound}` : `打开${activeTheme.sound}`}>
                  <Icon>{ambient ? '♪' : '×'}</Icon>
                </button>
              </div>
            </section>

            <aside className="zc-context">
              <header className="zc-panel-header">
                <div><span>此刻</span><h2>今晚的节奏</h2></div>
                <button type="button" className="zc-icon-button" title="更多选项">•••</button>
              </header>

              <section className="zc-presence-summary">
                <div><span>已在场</span><strong>42 分钟</strong></div>
                <div className="zc-progress">{Array.from({ length: 8 }, (_, index) => <i key={index} className={index < 5 ? 'active' : ''} />)}</div>
                <footer><span>♨ 连续 6 晚</span><span>目标 60 分钟</span></footer>
              </section>

              <section className="zc-tasks">
                <header><h3>放在桌上的事</h3><span>{completedTasks} / {tasks.length}</span></header>
                {tasks.map(task => (
                  <label key={task.id} className={task.done ? 'done' : ''}>
                    <input type="checkbox" checked={task.done} onChange={() => toggleTask(task.id)} />
                    <i>✓</i><span>{task.text}</span>
                  </label>
                ))}
              </section>

              <section className="zc-voice-preview">
                <Icon>◎</Icon>
                <span><small>一段留声等待播放</small><strong>“等你忙完再听”</strong><small>阿禾 · 00:18</small></span>
                <button type="button" onClick={playVoice} title="播放留声">▶</button>
              </section>

              <div className="zc-panel-actions">
                <button type="button" onClick={() => setModal('desk')}>♧ 邀请同桌</button>
                <button type="button" className="primary" onClick={() => setModal('voice')}>● 留一句话</button>
              </div>
            </aside>
          </div>
        </section>
      </main>

      {modal === 'desk' && (
        <Modal eyebrow="同桌" title="有人在，沉默也很好" onClose={closeModal}>
          <div className="zc-desk-people">
            <Person avatar={nickname.slice(0, 1)} name="你" state={`专注中 · ${formatTime(seconds)}`} />
            <div className="zc-connection"><i /><span>⌂</span><i /></div>
            <Person avatar="禾" name="阿禾" state="专注中 · 18:06" friend />
          </div>
          <div className="zc-invite">
            <span><small>今晚的同桌码</small><strong>YUZU-2048</strong><small>30 分钟后失效</small></span>
            <button type="button" onClick={copyDeskCode}>▣ 复制</button>
          </div>
          <div className="zc-rules">
            <Rule icon="◇" title="安静模式" text="无需持续聊天" />
            <Rule icon="◉" title="轻状态" text="只分享是否在场" />
            <Rule icon="↗" title="随时离开" text="不发送离开提醒" />
          </div>
        </Modal>
      )}

      {modal === 'voice' && (
        <Modal eyebrow="留声机" title="把这句话留到合适的时候" onClose={closeModal}>
          <div className="zc-recorder">
            <div className={`zc-record-disc ${recording ? 'recording' : ''}`}><i /></div>
            <div className={`zc-wave ${recording ? 'active' : ''}`}>
              {Array.from({ length: 12 }, (_, index) => <i key={index} />)}
            </div>
            <strong>{formatTime(recordSeconds)}</strong>
            <button type="button" className={recording ? 'recording' : ''} onClick={toggleRecording}>
              <i />{recording ? '完成录制' : recordReady ? '重新录制' : '开始录制'}
            </button>
          </div>
          <fieldset className="zc-delivery">
            <legend>让它什么时候抵达？</legend>
            {[
              ['专注结束后', '大约 24 分钟'],
              ['今晚睡前', '23:30'],
              ['下次上线时', '等待对方出现'],
            ].map(([label, meta]) => (
              <label key={label} className={delivery === label ? 'selected' : ''}>
                <input type="radio" name="delivery" checked={delivery === label} onChange={() => setDelivery(label)} />
                <span>{label}</span><small>{meta}</small>
              </label>
            ))}
          </fieldset>
          <button type="button" className="zc-wide-primary" disabled={!recordReady} onClick={saveVoice}>▷ 放进留声机</button>
        </Modal>
      )}

      {modal === 'memory' && (
        <Modal eyebrow="共同记忆" title="一起坐过的时间" onClose={closeModal}>
          <div className="zc-memory-stats">
            <span><strong>12</strong><small>次同桌</small></span>
            <span><strong>8h 24m</strong><small>共同在场</small></span>
            <span><strong>7</strong><small>段留声</small></span>
          </div>
          <div className="zc-timeline">
            <Memory time="今晚 · 22:26" title="雨夜书桌" text="你们一起完成了 42 分钟专注。" />
            <Memory time="8 月 8 日" title="一段迟到的留声" text="“面试结束记得告诉我。”" />
            <Memory time="8 月 3 日" title="第一次同桌" text="两盏台灯从那天开始同时亮起。" />
          </div>
        </Modal>
      )}

      {modal === 'theme' && (
        <Modal eyebrow="房间设置" title="今晚住在哪里" onClose={closeModal}>
          <div className="zc-themes">
            {ROOM_THEMES.map((theme, index) => (
              <button type="button" key={theme.name} className={themeIndex === index ? 'active' : ''} onClick={() => {
                setThemeIndex(index);
                showToast(`已换到${theme.name}`);
              }}>
                <img src={theme.src} alt={theme.name} />
                <span>{theme.name}</span>
                {themeIndex === index && <i>✓</i>}
              </button>
            ))}
          </div>
          <Setting title="窗外天气" text="雨滴会在窗口上缓慢落下" active={rain} onClick={() => setRain(value => !value)} />
        </Modal>
      )}

      {toast && <div className="zc-toast"><span>✓</span>{toast}</div>}
      <style>{styles}</style>
    </div>
  );
};

const Modal = ({ eyebrow, title, onClose, children }) => (
  <div className="zc-modal-layer" role="presentation">
    <button type="button" className="zc-backdrop" aria-label="关闭" onClick={onClose} />
    <section className="zc-modal" role="dialog" aria-modal="true" aria-label={title}>
      <header><div><span>{eyebrow}</span><h2>{title}</h2></div><button type="button" onClick={onClose} aria-label="关闭">×</button></header>
      {children}
    </section>
  </div>
);

const Person = ({ avatar, name, state, friend }) => (
  <div className="zc-person"><i className={friend ? 'friend' : ''}>{avatar}</i><strong>{name}</strong><small>{state}</small></div>
);

const Rule = ({ icon, title, text }) => (
  <div><Icon>{icon}</Icon><span><strong>{title}</strong><small>{text}</small></span></div>
);

const Memory = ({ time, title, text }) => (
  <article><time>{time}</time><strong>{title}</strong><p>{text}</p></article>
);

const Setting = ({ title, text, active, onClick }) => (
  <div className="zc-setting"><span><strong>{title}</strong><small>{text}</small></span><button type="button" className={active ? 'active' : ''} onClick={onClick}><i /></button></div>
);

const styles = `
  .zc-root {
    --ink: #f7f0e6;
    --muted: #aaa7a2;
    --surface: #17191d;
    --surface-2: #202228;
    --line: rgba(255,255,255,.1);
    --amber: #e2a14f;
    --amber-soft: #ffd893;
    --green: #7fa477;
    min-height: 100vh;
    color: var(--ink);
    background: #2c2724;
    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", "Microsoft YaHei", sans-serif;
    font-synthesis: none;
  }
  .zc-root * { box-sizing: border-box; letter-spacing: 0; }
  .zc-root button, .zc-root input { font: inherit; }
  .zc-root button { color: inherit; }
  .zc-root button:focus-visible, .zc-root input:focus-visible { outline: 2px solid var(--amber-soft); outline-offset: 2px; }
  .zc-desktop { display: grid; min-height: 100vh; place-items: center; padding: 24px; }
  .zc-window { width: min(1480px, calc(100vw - 48px)); height: min(900px, calc(100vh - 48px)); min-height: 620px; overflow: hidden; border: 1px solid rgba(255,255,255,.15); border-radius: 8px; background: var(--surface); box-shadow: 0 24px 70px rgba(0,0,0,.5); }
  .zc-titlebar { position: relative; z-index: 20; display: grid; height: 52px; grid-template-columns: 1fr auto 1fr; align-items: center; border-bottom: 1px solid var(--line); background: #1c1e22; padding: 0 16px; }
  .zc-window-controls, .zc-brand, .zc-title-status, .zc-title-actions { display: flex; align-items: center; }
  .zc-window-controls { gap: 8px; }
  .zc-dot { width: 12px; height: 12px; border-radius: 50%; }
  .zc-red { background: #ff6258; } .zc-yellow { background: #ffbd2e; } .zc-green { background: #28c840; }
  .zc-brand { position: absolute; left: 72px; gap: 9px; font-size: 14px; }
  .zc-brand-mark { display: grid; width: 26px; height: 26px; place-items: center; border: 1px solid #9b7040; border-radius: 5px; background: #6f4930; color: #ffe0a7; font-size: 13px; }
  .zc-title-status { grid-column: 2; gap: 15px; color: var(--muted); font-size: 12px; font-variant-numeric: tabular-nums; }
  .zc-title-actions { grid-column: 3; justify-self: end; gap: 8px; }
  .zc-icon-button { position: relative; display: grid; width: 34px; height: 34px; place-items: center; border: 0; border-radius: 6px; background: transparent; color: var(--muted); cursor: pointer; }
  .zc-icon-button:hover { background: rgba(255,255,255,.07); color: var(--ink); }
  .zc-avatar { display: grid; width: 30px; height: 30px; place-items: center; border: 1px solid #7e5c42; border-radius: 6px; background: #5b4539; color: #ffe3b7; font-size: 12px; font-weight: 700; cursor: pointer; }
  .zc-notice { position: absolute; top: 6px; right: 6px; width: 6px; height: 6px; border-radius: 50%; background: #dc6b5d; }
  .zc-layout { display: grid; height: calc(100% - 52px); grid-template-columns: 72px minmax(0,1fr) 304px; }
  .zc-nav { position: relative; z-index: 15; display: flex; flex-direction: column; justify-content: space-between; border-right: 1px solid var(--line); background: #181a1e; padding: 14px 8px; }
  .zc-nav-group { display: grid; gap: 6px; }
  .zc-nav-button { position: relative; display: grid; width: 56px; min-height: 52px; place-items: center; gap: 3px; border: 0; border-radius: 6px; background: transparent; color: #8d8f94; cursor: pointer; font-size: 10px; }
  .zc-nav-button:hover { background: rgba(255,255,255,.06); color: #d5d3ce; }
  .zc-nav-button.active { background: #2d2925; color: var(--amber-soft); }
  .zc-nav-button.active:before { position: absolute; left: -8px; width: 3px; height: 24px; border-radius: 0 3px 3px 0; background: var(--amber); content: ""; }
  .zc-nav-button b { position: absolute; top: 5px; right: 8px; display: grid; min-width: 16px; height: 16px; place-items: center; border: 2px solid #181a1e; border-radius: 50%; background: #b85d4e; color: white; font-size: 9px; }
  .zc-icon { display: inline-grid; min-width: 20px; min-height: 20px; place-items: center; font-family: ui-monospace, monospace; font-style: normal; }
  .zc-nav-button > .zc-icon { font-size: 19px; }
  .zc-stage { position: relative; min-width: 0; overflow: hidden; background: #0e1827; isolation: isolate; }
  .zc-stage > img { position: absolute; inset: 0; z-index: -3; width: 100%; height: 100%; object-fit: cover; object-position: center; transition: filter .35s ease; }
  .zc-stage.state-quiet > img { filter: brightness(.78) saturate(.85); }
  .zc-stage.state-break > img { filter: brightness(1.08) saturate(1.03); }
  .zc-stage.state-away > img { filter: brightness(.64) saturate(.75); }
  .zc-stage-shade { position: absolute; inset: 0; z-index: -2; box-shadow: inset 0 90px 110px rgba(5,8,13,.3), inset 0 -100px 120px rgba(5,7,10,.46); pointer-events: none; }
  .zc-rain { position: absolute; inset: 0; z-index: -1; overflow: hidden; pointer-events: none; }
  .zc-rain i { position: absolute; top: -30px; width: 1px; background: rgba(171,207,245,.55); animation-name: zc-rain-fall; animation-timing-function: linear; animation-iteration-count: infinite; transform: rotate(10deg); }
  @keyframes zc-rain-fall { to { transform: translate(80px,110vh) rotate(10deg); } }
  .zc-scene-heading { position: absolute; top: 28px; left: 30px; max-width: 55%; text-shadow: 0 2px 10px rgba(0,0,0,.72); }
  .zc-scene-heading span, .zc-panel-header span, .zc-modal > header span { display: block; margin-bottom: 5px; color: var(--amber-soft); font-size: 11px; font-weight: 700; }
  .zc-scene-heading h1 { margin: 0; font-family: ui-monospace, "PingFang SC", monospace; font-size: clamp(20px,2vw,28px); line-height: 1.3; }
  .zc-friend { position: absolute; top: 26px; right: 22px; display: grid; grid-template-columns: 34px auto 8px; align-items: center; gap: 9px; min-width: 176px; border: 1px solid rgba(255,255,255,.16); border-radius: 7px; background: rgba(19,21,25,.85); padding: 7px 10px; text-align: left; cursor: pointer; backdrop-filter: blur(12px); }
  .zc-friend-avatar { display: grid; width: 34px; height: 34px; place-items: center; border: 1px solid #756352; border-radius: 5px; background: #57493e; color: #ffe7bc; font-size: 12px; font-weight: 700; }
  .zc-friend > span:nth-child(2) { display: grid; gap: 2px; }
  .zc-friend strong { font-size: 12px; } .zc-friend small { color: var(--muted); font-size: 10px; }
  .zc-friend > i { width: 7px; height: 7px; border-radius: 50%; background: #74b97b; box-shadow: 0 0 0 4px rgba(116,185,123,.12); }
  .zc-scene-controls { position: absolute; right: 22px; bottom: 22px; left: 22px; display: flex; align-items: center; gap: 10px; }
  .zc-state-control { position: relative; }
  .zc-state-button, .zc-timer, .zc-sound { border: 1px solid rgba(255,255,255,.16); background: rgba(19,21,25,.9); box-shadow: 0 8px 24px rgba(0,0,0,.24); backdrop-filter: blur(12px); }
  .zc-state-button { display: flex; height: 46px; min-width: 126px; align-items: center; justify-content: center; gap: 8px; border-radius: 7px; cursor: pointer; font-size: 12px; font-weight: 650; }
  .zc-state-button > i { width: 8px; height: 8px; border-radius: 50%; background: var(--green); box-shadow: 0 0 0 4px rgba(127,164,119,.14); }
  .zc-state-menu { position: absolute; bottom: 55px; left: 0; width: 246px; overflow: hidden; border: 1px solid var(--line); border-radius: 7px; background: #1c1e22; box-shadow: 0 14px 34px rgba(0,0,0,.42); }
  .zc-state-menu button { display: grid; width: 100%; grid-template-columns: 28px 1fr; border: 0; border-bottom: 1px solid var(--line); background: transparent; padding: 10px 12px; text-align: left; cursor: pointer; }
  .zc-state-menu button:hover { background: #27292e; }
  .zc-state-menu button > span { display: grid; gap: 2px; } .zc-state-menu strong { font-size: 12px; } .zc-state-menu small { color: var(--muted); font-size: 10px; }
  .zc-timer { display: grid; height: 46px; grid-template-columns: 36px 72px 36px; align-items: center; border-radius: 7px; padding: 0 5px; }
  .zc-timer button { display: grid; width: 32px; height: 32px; place-items: center; border: 0; border-radius: 6px; background: transparent; cursor: pointer; }
  .zc-timer button:hover { background: rgba(255,255,255,.08); }
  .zc-timer > span { display: grid; place-items: center; }
  .zc-timer strong { font-family: ui-monospace, monospace; font-size: 15px; } .zc-timer small { color: var(--muted); font-size: 9px; }
  .zc-sound { display: grid; width: 46px; height: 46px; place-items: center; border-radius: 7px; cursor: pointer; color: #aaa; }
  .zc-sound.active { color: #78a8cf; }
  .zc-context { position: relative; z-index: 14; display: flex; flex-direction: column; overflow-y: auto; border-left: 1px solid var(--line); background: #1d1f23; padding: 22px 20px 18px; }
  .zc-panel-header { display: flex; align-items: center; justify-content: space-between; }
  .zc-panel-header h2, .zc-modal h2 { margin: 0; font-size: 18px; line-height: 1.35; }
  .zc-presence-summary { padding: 22px 0 20px; border-bottom: 1px solid var(--line); }
  .zc-presence-summary > div:first-child { display: flex; align-items: baseline; justify-content: space-between; color: var(--muted); font-size: 11px; }
  .zc-presence-summary > div strong { color: var(--ink); font-size: 20px; }
  .zc-progress { display: grid; height: 6px; grid-template-columns: repeat(8,1fr); gap: 4px; margin: 14px 0 10px; }
  .zc-progress i { border-radius: 2px; background: #3e4045; } .zc-progress i.active { background: var(--amber); }
  .zc-presence-summary footer { display: flex; justify-content: space-between; color: var(--muted); font-size: 10px; }
  .zc-presence-summary footer span:first-child { color: #d8b37b; }
  .zc-tasks { padding: 20px 0; border-bottom: 1px solid var(--line); }
  .zc-tasks header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
  .zc-tasks h3 { margin: 0; font-size: 13px; } .zc-tasks header span { color: var(--muted); font-size: 10px; }
  .zc-tasks label { display: grid; min-height: 36px; grid-template-columns: 22px 1fr; align-items: center; cursor: pointer; font-size: 11px; }
  .zc-tasks input { position: absolute; opacity: 0; }
  .zc-tasks label i { display: grid; width: 16px; height: 16px; place-items: center; border: 1px solid #5e6065; border-radius: 4px; color: transparent; font-style: normal; }
  .zc-tasks label.done i { border-color: #748c6f; background: #52694f; color: #eaf4e8; }
  .zc-tasks label.done span { color: #777a7f; text-decoration: line-through; }
  .zc-voice-preview { display: grid; grid-template-columns: 38px 1fr 34px; align-items: center; gap: 10px; margin-top: 18px; border: 1px solid #453b30; border-radius: 7px; background: #26231f; padding: 11px; }
  .zc-voice-preview > .zc-icon { width: 38px; height: 38px; border-radius: 6px; background: #6b4933; color: #f7c476; }
  .zc-voice-preview > span { display: grid; min-width: 0; gap: 3px; }
  .zc-voice-preview small { color: var(--muted); font-size: 9px; } .zc-voice-preview strong { overflow: hidden; font-size: 11px; text-overflow: ellipsis; white-space: nowrap; }
  .zc-voice-preview button { width: 32px; height: 32px; border: 0; border-radius: 50%; background: var(--amber); color: #2f251b; cursor: pointer; }
  .zc-panel-actions { display: flex; gap: 8px; margin-top: auto; padding-top: 18px; }
  .zc-panel-actions button, .zc-invite button, .zc-wide-primary { min-height: 38px; border: 1px solid #4c4e54; border-radius: 6px; background: #292b30; padding: 0 12px; cursor: pointer; font-size: 11px; font-weight: 650; }
  .zc-panel-actions button { flex: 1; }
  .zc-panel-actions .primary, .zc-wide-primary { border-color: #d39241; background: #d99a4c; color: #2b2117; }
  .zc-modal-layer { position: fixed; inset: 0; z-index: 100; display: grid; place-items: center; padding: 20px; }
  .zc-backdrop { position: absolute; inset: 0; border: 0; background: rgba(7,8,10,.74); backdrop-filter: blur(4px); }
  .zc-modal { position: relative; width: min(520px,calc(100vw - 32px)); max-height: min(760px,calc(100vh - 40px)); overflow-y: auto; border: 1px solid #44464d; border-radius: 8px; background: #1c1e22; padding: 22px; box-shadow: 0 24px 80px rgba(0,0,0,.55); }
  .zc-modal > header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; }
  .zc-modal > header > button { display: grid; width: 34px; height: 34px; place-items: center; border: 0; border-radius: 6px; background: transparent; color: var(--muted); cursor: pointer; font-size: 20px; }
  .zc-desk-people { display: grid; grid-template-columns: 1fr 110px 1fr; align-items: center; padding: 16px 0 24px; }
  .zc-person { display: grid; place-items: center; text-align: center; }
  .zc-person > i { display: grid; width: 54px; height: 54px; margin-bottom: 10px; place-items: center; border: 1px solid #756352; border-radius: 7px; background: #56473c; color: #ffe7bc; font-style: normal; font-weight: 700; }
  .zc-person > i.friend { background: #3e5057; color: #cde6e8; }
  .zc-person strong { font-size: 12px; } .zc-person small { margin-top: 4px; color: var(--muted); font-size: 10px; }
  .zc-connection { display: grid; grid-template-columns: 1fr 28px 1fr; align-items: center; color: var(--amber); text-align: center; }
  .zc-connection i { height: 1px; background: #66533b; }
  .zc-invite { display: flex; align-items: center; justify-content: space-between; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); padding: 18px 0; }
  .zc-invite > span { display: grid; gap: 3px; } .zc-invite small { color: var(--muted); font-size: 10px; } .zc-invite strong { font-family: ui-monospace, monospace; font-size: 20px; }
  .zc-rules { display: grid; grid-template-columns: repeat(3,1fr); gap: 12px; padding-top: 20px; }
  .zc-rules > div { display: grid; grid-template-columns: 24px 1fr; gap: 8px; }
  .zc-rules > div > span { display: grid; gap: 3px; } .zc-rules strong { font-size: 10px; } .zc-rules small { color: var(--muted); font-size: 9px; }
  .zc-recorder { display: grid; min-height: 226px; place-items: center; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); padding: 20px 0; }
  .zc-record-disc { display: grid; width: 76px; height: 76px; place-items: center; border: 8px double #34363d; border-radius: 50%; background: #111216; box-shadow: inset 0 0 0 7px #24262b, inset 0 0 0 10px #111216; }
  .zc-record-disc > i { width: 16px; height: 16px; border-radius: 50%; background: #dc6b5d; }
  .zc-record-disc.recording { animation: zc-spin 2.4s linear infinite; } @keyframes zc-spin { to { transform: rotate(360deg); } }
  .zc-wave { display: flex; height: 32px; align-items: center; gap: 4px; margin: 12px 0 6px; }
  .zc-wave i { width: 3px; height: 5px; border-radius: 2px; background: #64666c; }
  .zc-wave.active i { animation: zc-wave .7s ease-in-out infinite alternate; } .zc-wave.active i:nth-child(2n) { animation-delay: .12s; } .zc-wave.active i:nth-child(3n) { animation-delay: .26s; }
  @keyframes zc-wave { to { height: 28px; background: var(--amber); } }
  .zc-recorder > strong { margin-bottom: 12px; font-family: ui-monospace, monospace; font-size: 14px; }
  .zc-recorder > button { display: flex; min-height: 38px; align-items: center; gap: 7px; border: 1px solid #5f4944; border-radius: 6px; background: #332827; padding: 0 13px; color: #ffd6cf; cursor: pointer; font-size: 11px; }
  .zc-recorder > button > i { width: 8px; height: 8px; border-radius: 50%; background: #dc6b5d; } .zc-recorder > button.recording > i { border-radius: 2px; }
  .zc-delivery { display: grid; gap: 8px; margin: 20px 0; border: 0; padding: 0; }
  .zc-delivery legend { margin-bottom: 10px; font-size: 12px; font-weight: 650; }
  .zc-delivery label { display: grid; min-height: 42px; grid-template-columns: 22px 1fr auto; align-items: center; border: 1px solid #3d3f45; border-radius: 6px; padding: 0 12px; cursor: pointer; }
  .zc-delivery label.selected { border-color: #9f7542; background: #28231e; }
  .zc-delivery input { accent-color: var(--amber); } .zc-delivery span { font-size: 11px; } .zc-delivery small { color: var(--muted); font-size: 9px; }
  .zc-wide-primary { width: 100%; } .zc-wide-primary:disabled { cursor: not-allowed; filter: grayscale(.7); opacity: .45; }
  .zc-memory-stats { display: grid; grid-template-columns: repeat(3,1fr); border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); }
  .zc-memory-stats > span { display: grid; gap: 4px; padding: 18px 8px; text-align: center; } .zc-memory-stats > span + span { border-left: 1px solid var(--line); }
  .zc-memory-stats strong { color: var(--amber-soft); font-size: 18px; } .zc-memory-stats small { color: var(--muted); font-size: 9px; }
  .zc-timeline { display: grid; padding: 14px 0 0 19px; }
  .zc-timeline article { position: relative; border-bottom: 1px solid var(--line); padding: 12px 0 14px; }
  .zc-timeline article:before { position: absolute; top: 17px; left: -18px; width: 8px; height: 8px; border-radius: 50%; background: var(--amber); content: ""; }
  .zc-timeline time { display: block; color: var(--muted); font-size: 9px; } .zc-timeline strong { display: block; margin-top: 4px; font-size: 12px; } .zc-timeline p { margin: 5px 0 0; color: #b9b7b1; font-size: 10px; }
  .zc-themes { display: grid; grid-template-columns: repeat(auto-fit,minmax(140px,160px)); gap: 10px; margin-bottom: 20px; }
  .zc-themes button { position: relative; overflow: hidden; border: 1px solid #45474d; border-radius: 6px; background: #25272c; padding: 0 0 9px; color: var(--muted); text-align: left; cursor: pointer; }
  .zc-themes button.active { border-color: var(--amber); color: var(--ink); }
  .zc-themes img { display: block; width: 100%; aspect-ratio: 16/10; margin-bottom: 8px; object-fit: cover; }
  .zc-themes span { padding-left: 9px; font-size: 10px; } .zc-themes button > i { position: absolute; top: 6px; right: 6px; display: grid; width: 18px; height: 18px; place-items: center; border-radius: 50%; background: var(--amber); color: #251b12; font-style: normal; font-size: 11px; }
  .zc-setting { display: flex; min-height: 58px; align-items: center; justify-content: space-between; border-top: 1px solid var(--line); }
  .zc-setting > span { display: grid; gap: 4px; } .zc-setting strong { font-size: 11px; } .zc-setting small { color: var(--muted); font-size: 9px; }
  .zc-setting > button { width: 36px; height: 20px; border: 0; border-radius: 10px; background: #4a4c51; padding: 2px; cursor: pointer; }
  .zc-setting > button i { display: block; width: 16px; height: 16px; border-radius: 50%; background: #d5d4d0; transition: transform .16s ease; }
  .zc-setting > button.active { background: #8c693f; } .zc-setting > button.active i { transform: translateX(16px); background: #ffe1a7; }
  .zc-toast { position: fixed; z-index: 200; bottom: 26px; left: 50%; display: flex; min-height: 42px; align-items: center; gap: 8px; border: 1px solid #4b4e53; border-radius: 7px; background: #202227; padding: 0 16px; box-shadow: 0 12px 34px rgba(0,0,0,.4); color: #ece8e1; font-size: 11px; transform: translateX(-50%); }
  .zc-toast span { color: #83b27c; }
  @media (max-width: 1120px) { .zc-layout { grid-template-columns: 68px minmax(0,1fr); } .zc-context { display: none; } }
  @media (max-width: 720px) {
    .zc-root, .zc-desktop { min-height: 100svh; } .zc-desktop { display: block; padding: 0; }
    .zc-window { width: 100%; height: 100svh; min-height: 560px; border: 0; border-radius: 0; }
    .zc-titlebar { height: 48px; grid-template-columns: 1fr auto; padding: 0 12px; }
    .zc-window-controls, .zc-title-status { display: none; } .zc-brand { position: static; } .zc-title-actions { grid-column: 2; }
    .zc-layout { height: calc(100% - 48px); grid-template-columns: 1fr; grid-template-rows: minmax(0,1fr) 66px; }
    .zc-nav { grid-row: 2; display: grid; grid-template-columns: repeat(5,1fr); border-top: 1px solid var(--line); border-right: 0; padding: 5px 8px 6px; }
    .zc-nav-group { display: contents; } .zc-nav-button { width: 100%; min-height: 54px; } .zc-nav-button.active:before { top: -5px; left: 50%; width: 24px; height: 3px; transform: translateX(-50%); }
    .zc-stage { grid-row: 1; } .zc-stage > img { object-position: 56% center; }
    .zc-scene-heading { top: 22px; left: 18px; max-width: 58%; } .zc-scene-heading h1 { font-size: 19px; }
    .zc-friend { top: 20px; right: 14px; min-width: 0; grid-template-columns: 30px 8px; padding: 6px 8px; } .zc-friend-avatar { width: 30px; height: 30px; } .zc-friend > span:nth-child(2) { display: none; }
    .zc-scene-controls { right: 14px; bottom: 20px; left: 14px; } .zc-state-button { min-width: 112px; } .zc-timer { margin-left: auto; grid-template-columns: 32px 64px 32px; } .zc-sound { display: none; }
    .zc-modal-layer { align-items: end; padding: 0; } .zc-modal { width: 100%; max-height: 88svh; border-right: 0; border-bottom: 0; border-left: 0; border-radius: 8px 8px 0 0; padding: 20px 18px; }
  }
  @media (max-width: 430px) { .zc-timer button:last-child { display: none; } .zc-timer { grid-template-columns: 32px 68px; } .zc-desk-people { grid-template-columns: 1fr 58px 1fr; } .zc-rules { grid-template-columns: 1fr; } .zc-themes { grid-template-columns: 1fr; } .zc-themes button { display: grid; grid-template-columns: 104px 1fr; align-items: center; padding: 0; } .zc-themes img { width: 104px; height: 62px; margin: 0; } }
  @media (prefers-reduced-motion: reduce) { .zc-root *, .zc-root *:before, .zc-root *:after { animation-duration: 1ms !important; animation-iteration-count: 1 !important; transition-duration: 1ms !important; } }
`;

export default ZaichangDemo;
