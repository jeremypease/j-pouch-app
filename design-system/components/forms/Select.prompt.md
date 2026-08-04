Native dropdown styled to match Input — symptom type, medication name, recovery stage.

```jsx
<Select label="Consistency" value={v} onChange={e=>setV(e.target.value)} options={[{label:'Liquid',value:'liquid'},{label:'Formed',value:'formed'}]} />
```
