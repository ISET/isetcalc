import React, { useState, useRef, useEffect, useMemo, useCallback } from 'react'
import { render } from 'react-dom'
import { AgGridReact } from 'ag-grid-react' // the AG Grid React Component
import MyToolPanel from './myToolPanel.jsx'
// import MyStatusPanel from './myStatusPanel.jsx';

import 'ag-grid-community/styles/ag-grid.css' // Core grid CSS, always needed
import 'ag-grid-community/styles/ag-theme-alpine.css' // Optional theme CSS
import ImageRenderer from './ImageRenderer.jsx'

// Core UI & Bootstrap
import '@coreui/coreui/dist/css/coreui.min.css'
import 'bootstrap/dist/css/bootstrap.min.css'
import { CContainer, CRow, CCol, CImage } from '@coreui/react'

// Load our rendered sensor images
let dataDir = './data/'
let imageDir = '/images/' // Should use /public by default?
let imageData = require(dataDir + 'metadata.json') 

let previewImage = imageDir + imageData[0].jpegName
let testImage = 'http://stanford.edu/favicon.ico'

var rows
for (let ii = 0; ii < imageData.length; ii++) {
  // keys seem to have to be unique so we'll add a unique integer!
  let newRow = [
    {
      thumbnail: imageDir + imageData[ii].thumbnailName,
      scene: imageData[ii].scenename,
      lens: imageData[ii].opticsname,
      sensor: imageData[ii].sensorname,
      preview: imageDir + imageData[ii].jpegName
    }
  ]
  if (ii == 0) {
    rows = [newRow]
  } else {
    rows = rows.concat(newRow)
  }
}

const App = () => {
  const gridRef = useRef() // Optional - for accessing Grid's API
  //const [rowData, setRowData] = useState(); // Set rowData to Array of Objects, one Object per Row
  // let the grid know which columns and what data to use
  const [rowData] = useState(rows)

  // Each Column Definition results in one Column.
  const [columnDefs, setColumnDefs] = useState([
    {
      headerName: 'Thumbnail',
      width: 128,
      field: 'thumbnail',
      cellRenderer: ImageRenderer
    },
    { headerName: 'Scene', field: 'scene', filter: true },
    { headerName: 'Lens Used', field: 'lens', filter: true },
    { headerName: 'Sensor', field: 'sensor', filter: true },
    { headerName: 'Preview', field: 'preview', hide: true}
  ])

  // DefaultColDef sets props common to all Columns
  const defaultColDef = useMemo(() => ({
    sortable: true
  }))

  // This doesn't seem to do anything
  const rowDefs = useState([{ height: 128 }])

  // This either
  const defaultRowDef = useMemo(() => ({
    // height: 400
  }))

  // Example of consuming Grid Event
  const cellClickedListener = useCallback(event => {
    console.log('cellClicked', event)
  }, [])

  // Example of consuming Grid Event
  let pImage
  let pI // This will be the preview image element
  const rowClickedListener = useCallback(event => {
    //console.log('cellClicked', event)
    console.log('Row Clicked: \n', event);
    pI = document.getElementById('previewImage')
//    var pI = React.findDOMNode(this.refs.1);
    pI.src = event.data.preview;

    // NEED TO also change caption here, in a similar way

  }, [])
  const sideBar = useMemo(
    () => ({
      toolPanels: [
        'columns',
        'filters',
        {
          id: 'myToolPanel',
          labelDefault: 'My Tool Panel',
          labelKey: 'myToolPanel',
          iconKey: 'filter',
          toolPanel: MyToolPanel
        }
      ],
      defaultToolPanel: 'myToolPanel'
    }),
    []
  )

  // Example using Grid's API
  const buttonListener = useCallback(e => {
    gridRef.current.api.deselectAll()
  }, [])

  return (
    <CContainer fluid>
      {/* Example using Grid's API */}
      <CRow className='align-items-start'>
        <CCol className='align-items-start'>
          <div className='ag-theme-alpine' style={{ width: 800, height: 600 }}>
            <AgGridReact
              ref={gridRef} // Ref for accessing Grid's API
              rowData={rowData} // Row Data for Rows
              columnDefs={columnDefs} // Column Defs for Columns
              defaultColDef={defaultColDef} // Default Column Properties
              animateRows={true} // Optional - set to 'true' to have rows animate when sorted
              rowSelection='single' // Options - allows click selection of rows
              onCellClicked={cellClickedListener} // Optional - registering for Grid Event
              onRowClicked={rowClickedListener} // Optional - registering for Grid Event
            />
          </div>
        </CCol>
        <CCol>
          <CRow className='align-items-center'>
            <CImage id='previewImage'
              rounded
              thumbnail
              src={previewImage}
              width={400}
              height={400}
            />
          </CRow>
          <CRow className='align-items-center'>Image Caption Here</CRow>
          <CRow>
            <button onClick={buttonListener}>Download Sensor Image (volts)</button>
            <button onClick={buttonListener}>Download Processed Image (rgb)</button>
            <button onClick={buttonListener}>Download Optical Image (large)</button>
          </CRow>
        </CCol>
      </CRow>
    </CContainer>
  )
}

export default App
